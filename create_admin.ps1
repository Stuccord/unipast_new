$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6YnFzdmZ4cGtheWdvY2pvZGprIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4NDYxNCwiZXhwIjoyMDg4MzYwNjE0fQ.Yd2Y-L4QLeCtx--6-pCBWF2QI2dyw6RgWOF0yUzicjg"
$supabaseUrl = "https://hzbqsvfxpkaygocjodjk.supabase.co"
$email = "admin@unipast.com"
$password = "Ebube123..."

$headers = @{
    "apikey"        = $serviceRoleKey
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type"  = "application/json"
}

Write-Host "Step 1: Creating user in Supabase Auth..."

$body = @{
    email         = $email
    password      = $password
    email_confirm = $true
} | ConvertTo-Json

try {
    $createUserResponse = Invoke-RestMethod `
        -Uri "$supabaseUrl/auth/v1/admin/users" `
        -Method Post `
        -Headers $headers `
        -Body $body

    $userId = $createUserResponse.id
    Write-Host "SUCCESS: User created with ID: $userId"

    Write-Host ""
    Write-Host "Step 2: Setting is_admin = true in profiles table..."

    $profileBody = @{
        id        = $userId
        is_admin  = $true
        full_name = "Admin"
    } | ConvertTo-Json

    Invoke-RestMethod `
        -Uri "$supabaseUrl/rest/v1/profiles?id=eq.$userId" `
        -Method Patch `
        -Headers ($headers + @{ "Prefer" = "return=representation" }) `
        -Body $profileBody | Out-Null

    Write-Host "SUCCESS: Profile updated - is_admin set to true."
    Write-Host ""
    Write-Host "===== Admin account setup complete! ====="
    Write-Host "Email: $email"
    Write-Host "Password: $password"

}
catch {
    $errorMsg = $_.ErrorDetails.Message
    Write-Host "ERROR: $errorMsg"
    Write-Host "Raw error: $_"

    # If user already exists, try to find and update them
    if ($errorMsg -like "*already registered*" -or $errorMsg -like "*already exists*") {
        Write-Host ""
        Write-Host "User already exists. Attempting to find user and set is_admin=true..."

        try {
            $usersResponse = Invoke-RestMethod `
                -Uri "$supabaseUrl/auth/v1/admin/users" `
                -Method Get `
                -Headers $headers

            $existingUser = $usersResponse.users | Where-Object { $_.email -eq $email }
            if ($existingUser) {
                $userId = $existingUser.id
                Write-Host "Found existing user with ID: $userId"

                $profileBody = @{ is_admin = $true } | ConvertTo-Json
                Invoke-RestMethod `
                    -Uri "$supabaseUrl/rest/v1/profiles?id=eq.$userId" `
                    -Method Patch `
                    -Headers ($headers + @{ "Prefer" = "return=representation" }) `
                    -Body $profileBody | Out-Null

                Write-Host "SUCCESS: is_admin set to true for existing user."
                Write-Host "Email: $email"
                Write-Host "Password: (your existing password)"
            }
            else {
                Write-Host "Could not find user with email $email in the users list."
            }
        }
        catch {
            Write-Host "Also failed to find existing user: $_"
        }
    }
}
