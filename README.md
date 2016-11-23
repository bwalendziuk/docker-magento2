# docker-magento2
This repo is one container to run magento2 on docker. You should not use this on a production environment.

# How to use
1. Download this repo
2. cd project/folder
3. **docker build -t bwalendziuk/dmagento:1.0 .**
4. **docker run --name=whatever -d -p 8001:80 -p 3307:3306 -v /src/to/local/magento:/srv/www bwalendziuk/dmagento:1.0**
5. Go to container **docker exec -it whatever bash**
6. Install magento

# Database credentials on container
1. Username: **admin**
2. Password: **admin**
3. Database: **magento**

# Links
1. http://devdocs.magento.com/
2. https://github.com/mageinferno
