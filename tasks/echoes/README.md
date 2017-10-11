# Echoes - A miniscule application

Basic useful feature list:

 * it echoes stuff


## Building image

`sudo docker build -t echoes .`

## Running container

`sudo docker run -p 8080:8080 -t echoes`

You should now be able to access the application at http://localhost:8080/

## Pushing image to ECR

```
sudo $(aws ecr get-login --no-include-email --region eu-west-1)
sudo docker tag echoes:latest 307921801440.dkr.ecr.eu-west-1.amazonaws.com/echoes:latest
sudo docker push 307921801440.dkr.ecr.eu-west-1.amazonaws.com/echoes:latest
```

# General information

Application written by [Jussi Heinonen](mailto:jussi.heinonen@ft.com)
