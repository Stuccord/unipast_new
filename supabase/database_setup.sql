-- 1. PROFILES TABLE (Mirrors auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  is_admin BOOLEAN DEFAULT false,
  is_rep BOOLEAN DEFAULT false,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" 
  ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'expired')),
  amount_pesewas INTEGER NOT NULL,
  currency TEXT DEFAULT 'GHS',
  paystack_ref TEXT UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  activated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast lookup by reference (used by webhook)
CREATE INDEX IF NOT EXISTS idx_subscriptions_paystack_ref ON public.subscriptions(paystack_ref);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);

-- Enable RLS on subscriptions
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view their own subscriptions" 
  ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

-- NOTE: Only the service_role (Edge Functions) is allowed to INSERT or UPDATE. 
-- Since service_role bypasses RLS, we do not need an explicit policy for it.

-- 3. TRANSACTIONS TABLE (Optional stats)
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  amount NUMERIC NOT NULL,
  currency TEXT DEFAULT 'GHS',
  status TEXT,
  paystack_ref TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on transactions
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
CREATE POLICY "Users can view their own transactions" 
  ON public.transactions FOR SELECT USING (auth.uid() = user_id);

-- 4. RPC: GET USER ID BY EMAIL
-- This allows Edge Functions to find a user UUID by email safely.
CREATE OR REPLACE FUNCTION get_user_id_by_email(user_email TEXT)
RETURNS TABLE (id UUID) 
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to read auth.users
SET search_path = public
AS $$
BEGIN
  RETURN QUERY SELECT u.id FROM auth.users u WHERE u.email = user_email;
END;
$$;

-- 5. TRIGGER: SYNC AUTH USERS TO PROFILES
-- Ensures every signup automatically creates a profile entry.

-- SECURITY NUKE: Drop any hidden triggers that might be granting unauthorized trials
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_profile_created_trial ON public.profiles;
DROP TRIGGER IF EXISTS on_activity_signup_trial ON public.activities;

CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  -- We ONLY insert the profile. NO subscription logic should EVER be here.
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 6. RPC: ATOMIC ACTIVATION (Called by Webhook & Client Fallback)
-- SECURITY DEFINER allows this to work even if the user has no direct table permissions.
CREATE OR REPLACE FUNCTION activate_subscription(
  target_user_id UUID,
  target_ref TEXT,
  target_amount_pesewas INTEGER,
  target_currency TEXT,
  target_expires_at TIMESTAMP WITH TIME ZONE,
  target_admin_secret TEXT -- NEW: Required secret to prevent unauthorized calls
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- ZERO-TRUST CHECK: Even if RLS or permissions are bypassed, this check will fail
  -- unless the secret key (matching the Edge Function environment) is provided.
  -- DEFAULT SECRET: 'UNIPAST_SECURE_2026'
  IF target_admin_secret IS NULL OR target_admin_secret != 'UNIPAST_SECURE_2026' THEN
    RAISE EXCEPTION 'Unauthorized: Invalid admin secret provided to activation RPC.';
  END IF;

  -- 1. Upsert the subscription
  INSERT INTO public.subscriptions (
    user_id, status, amount_pesewas, currency, paystack_ref, expires_at, activated_at
  )
  VALUES (
    target_user_id, 'active', target_amount_pesewas, target_currency, target_ref, target_expires_at, NOW()
  )
  ON CONFLICT (paystack_ref) DO UPDATE SET
    status = 'active',
    expires_at = EXCLUDED.expires_at,
    activated_at = NOW();

  -- 2. Record the transaction for financial stats
  INSERT INTO public.transactions (
    user_id, amount, currency, status, paystack_ref
  )
  VALUES (
    target_user_id, (target_amount_pesewas::numeric / 100.0), target_currency, 'success', target_ref
  )
  ON CONFLICT (paystack_ref) DO NOTHING;
END;
$$;

-- 7. SECURE THE RPC
-- We remove permissions from public and authenticated roles.
-- Only the service_role (used by Edge Functions) will have access.
REVOKE EXECUTE ON FUNCTION activate_subscription(UUID, TEXT, INTEGER, TEXT, TIMESTAMP WITH TIME ZONE, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION activate_subscription(UUID, TEXT, INTEGER, TEXT, TIMESTAMP WITH TIME ZONE, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION activate_subscription(UUID, TEXT, INTEGER, TEXT, TIMESTAMP WITH TIME ZONE, TEXT) FROM anon;
