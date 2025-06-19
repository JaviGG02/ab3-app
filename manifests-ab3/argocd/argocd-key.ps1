# Step 1: Create directory for SSH keys
New-Item -Path "$env:USERPROFILE\.ssh\argocd" -ItemType Directory -Force

# Step 2: Generate SSH key pair
ssh-keygen -t ed25519 -C "argocd" -f "$env:USERPROFILE\.ssh\argocd\id_ed25519" -N '""'

# Step 3: Display the public key (add this to GitHub deploy keys)
Get-Content "$env:USERPROFILE\.ssh\argocd\id_ed25519.pub"

# Step 4: Create Kubernetes secret with the private key
$privateKeyPath = "$env:USERPROFILE\.ssh\argocd\id_ed25519"
kubectl create secret generic argocd-repo-ssh -n argocd `
  --from-file=sshPrivateKey=$privateKeyPath `
  --from-literal=url=git@github.com:yourusername/your-repo.git

# Step 5: Verify the secret was created
kubectl get secret argocd-repo-ssh -n argocd
