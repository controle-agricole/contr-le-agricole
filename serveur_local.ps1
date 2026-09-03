
param([int]$Port=8765)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host ""
Write-Host "Application disponible sur http://localhost:$Port/" -ForegroundColor Green
Start-Process "http://localhost:$Port/"
Write-Host "Laissez cette fenêtre ouverte pendant l'utilisation." -ForegroundColor Yellow
Write-Host "Fermez-la pour arrêter le serveur." -ForegroundColor Yellow

$mime = @{
  ".html"="text/html; charset=utf-8"
  ".js"="application/javascript; charset=utf-8"
  ".json"="application/json; charset=utf-8"
  ".webmanifest"="application/manifest+json; charset=utf-8"
  ".png"="image/png"
  ".css"="text/css; charset=utf-8"
}
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $rel = $ctx.Request.Url.AbsolutePath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = "index.html" }
    $rel = [uri]::UnescapeDataString($rel)
    $path = Join-Path $Root $rel
    $full = [IO.Path]::GetFullPath($path)
    if (-not $full.StartsWith([IO.Path]::GetFullPath($Root))) {
      $ctx.Response.StatusCode = 403; $ctx.Response.Close(); continue
    }
    if (Test-Path $full -PathType Leaf) {
      $ext = [IO.Path]::GetExtension($full).ToLower()
      if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
      $bytes = [IO.File]::ReadAllBytes($full)
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
  } catch {
    if ($listener.IsListening) { Write-Host $_ }
  }
}
