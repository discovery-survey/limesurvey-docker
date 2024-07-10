server {
        listen 80;
        server_name discovery-survey.com;
        location / {
                return 301 https://$host;
        }
}


server {
        listen 443 ssl;
        server_name discovery-survey.com;
        ssl_certificate /home/survey-user/nginx/certs/discovery-survey.com.crt;
        ssl_certificate_key /home/survey-user/nginx/certs/discovery-survey.com.key;
        ssl_dhparam /home/survey-user/nginx/certs/dhparam.pem;

        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        client_max_body_size 100m;

        location / {
                proxy_pass http://127.0.0.1:8082;
                proxy_set_header Host $host;
        }
}
