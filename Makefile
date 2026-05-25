docker-build:
	git pull
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 349558942960.dkr.ecr.us-east-1.amazonaws.com
	docker build -t 349558942960.dkr.ecr.us-east-1.amazonaws.com/auth-service:$(image_tag) .
	trivy image 349558942960.dkr.ecr.us-east-1.amazonaws.com/auth-service:$(image_tag) -s CRITICAL,HIGH --ignore-unfixed
	docker push 349558942960.dkr.ecr.us-east-1.amazonaws.com/auth-service:$(image_tag)

eks-deploy:
	aws eks update-kubeconfig --name dev
	helm upgrade -i auth-service helm -f helm/values/auth-service.yml --set image_tag=$(image_tag)

argocd-deploy:
	argocd login $(argocd_server) --skip-test-tls --username admin --password $(argocd_admin_password)
	argocd app create auth-service --sync-policy auto --upsert --repo https://github.com/wmp-project/wmp-helm-v2.git --path . --dest-server https://kubernetes.default.svc   --dest-namespace default --helm-set-string image_tag=$(image_tag) --values values/auth-service.yml

