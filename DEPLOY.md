## Manual deployment checklist
You may notice that we're using different branches, environment variables, and files
depending on the build. Also note that <DOMAIN.TLD> is meant to be replaced with 
whatever domain and top-level domain is being used. Remove the angle brackets as well.


### [PRODUCTION]

#### Dockerfile.admin_panel
[ ] line 12: `    && git checkout master \`

#### Dockerfile.django
[ ] line 13: `    && git checkout master \`
 
#### Dockerfile.node
[ ] line 16: `    && git checkout master \`
[ ] line 23: `    && chown -R $USER:$USER /var/www/<DOMAIN.TLD>/html \
[ ] line 25: `    && cp -r dist/* /var/www/<DOMAIN.TLD>/html/`
[ ] line 27: `COPY <DOMAIN.TLD> /etc/nginx/sites-available/`
[ ] line 33: `RUN ln -s /etc/nginx/sites-available/<DOMAIN.TLD> /etc/nginx/sites-enabled/ \

#### <PRODUCTION_DOMAIN.TLD>
[ ] line 8:  `        root /var/www/<DOMAIN.TLD>/html;`
[ ] line 12: `        server_name <DOMAIN.TLD> www.<DOMAIN.TLD>;`


### [DEVELOPMENT]

#### Dockerfile.admin_panel
[ ] line 12: `    && git checkout devel \`

#### Dockerfile.django
[ ] line 13: `    && git checkout devel \`

#### Dockerfile.node
[ ] line 16: `    && git checkout devel \`
[ ] line 23: `    && chown -R $USER:$USER /var/www/<DOMAIN.TLD>/html \
[ ] line 25: `    && cp -r dist/* /var/www/<DOMAIN.TLD>/html/`
[ ] line 27: `COPY <DOMAIN.TLD> /etc/nginx/sites-available/`
[ ] line 33: `RUN ln -s /etc/nginx/sites-available/<DOMAIN.TLD> /etc/nginx/sites-enabled/ \

#### <DEVELOPMENT_DOMAIN.TLD>
[ ] line 8:  `        root /var/www/<DOMAIN.TLD>/html;`
[ ] line 12: `        server_name <DOMAIN.TLD> www.<DOMAIN.TLD>;`

### [PRODUCTION or DEVELOPMENT]
Substitute the right `<DOMAIN.TLD>` depending on development or production environment.

#### docker-compose.yml
[ ] line 11: `      - VIRTUAL_HOST=api.<DOMAIN.TLD>`
[ ] line 13: `      - LETSENCRYPT_HOST=api.<DOMAIN.TLD>`
[ ] line 14: `      - FRONTEND_HOST=<DOMAIN.TLD>`
[ ] line 29: `      - VIRTUAL_HOST=<DOMAIN.TLD>`
[ ] line 30: `      - LETSENCRYPT_HOST=<DOMAIN.TLD>`
[ ] line 45: `      - VIRTUAL_HOST=admin.steps2ar.org`
[ ] line 47: `      - LETSENCRYPT_HOST=admin.steps2ar.org`
[ ] line 69: `      - ${PWD}/cors.conf:/etc/nginx/vhost.d/api.<DOMAIN.TLD>`

#### web/.env.production
[ ] line 1: `RESTAPIURL='https://api.<PRODUCTION_DOMAIN.TLD>'`
[ ] line 2: `WEBSOCKETBASEURL='wss://api.<PRODUCTION_DOMAIN.TLD>'`

#### web/.env.devel
[ ] line 1: `RESTAPIURL='https://api.<DEVELOPMENT_DOMAIN.TLD>'`
[ ] line 2: `WEBSOCKETBASEURL='wss://api.<DEVELOPMENT_DOMAIN.TLD>'`

#### ereadingtool/settings.py
[ ] line 111+: Add <DOMAIN.TLD> to this list.