## Description

There is a web interface to this msg parser application to allow easy upload of individual .msg files, or many files compressed in a tar archive.

## Setup

Clone this repo, cd to the root of this project's directory, and run:

`docker-compose up`

The required images should be pulled from Docker Hub, so if you run into issues make sure to run `docker login`.

Once docker-compose is running, visit `localhost` in your browser, where you can upload files, and see the list of messages that were parsed from input.
