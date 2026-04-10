$headers = @{
    'apikey' = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6YnFzdmZ4cGtheWdvY2pvZGprIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4NDYxNCwiZXhwIjoyMDg4MzYwNjE0fQ.Yd2Y-L4QLeCtx--6-pCBWF2QI2dyw6RgWOF0yUzicjg'
    'Authorization' = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6YnFzdmZ4cGtheWdvY2pvZGprIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4NDYxNCwiZXhwIjoyMDg4MzYwNjE0fQ.Yd2Y-L4QLeCtx--6-pCBWF2QI2dyw6RgWOF0yUzicjg'
}
$uri = "https://hzbqsvfxpkaygocjodjk.supabase.co/rest/v1/profiles?is_admin=eq.true&select=full_name,id"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
$response | ConvertTo-Json
