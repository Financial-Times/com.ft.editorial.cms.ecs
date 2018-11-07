# ECS cluster for FT Editorial Technology



Repository to gather bells and whistles related to _Editorial Cluster Service_ experimentation.


## AWS command line tool

Alpine Linux based container image provides runtime for aws cli.

### Building image

`sudo docker build -t com.ft.editorial.ecs:dev .`

### Running container

`sudo docker run -it com.ft.editorial.ecs:dev`

### Configuring environment

To configure access id and secret run command  `aws configure`  inside container


## Sample application _echoes_

See _tasks/echoes/README.md_ for more details

