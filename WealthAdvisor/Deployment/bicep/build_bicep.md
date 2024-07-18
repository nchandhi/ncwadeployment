**Run below code to build bicep.json after changes**

az bicep build --file main.bicep


# Web app docker script
docker build --tag nalinichandhi/byc-wa-app:latest -f .\WebApp.Dockerfile .     
docker tag nalinichandhi/byc-wa-app:latest bycwacontainer.azurecr.io/byc-wa-app:latest 
az login
az acr login --name bycwacontainer     
docker push bycwacontainer.azurecr.io/byc-wa-app:latest
az acr update -n bycwacontainer --admin-enabled true
az acr update --name bycwacontainer --anonymous-pull-enabled


# Azure Function docker script
az login
docker build --tag nalinichandhi/byc-wa-fn:latest .
<!-- docker run -p 8080:80 -it nalinichandhi/wafunctionimage:latest -->
az acr login --name bycwacontainer
docker tag nalinichandhi/byc-wa-fn:latest bycwacontainer.azurecr.io/byc-wa-fn:latest
docker push bycwacontainer.azurecr.io/byc-wa-fn:latest
az acr update -n bycwacontainer --admin-enabled true
az acr update --name bycwacontainer --anonymous-pull-enabled