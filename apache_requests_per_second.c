/*
 * apache_requests_per_second
 *
 * Read lines from Apache's access_log each second and count them.
 * From this, we'll know how many requests per second Apache is
 * handling.
 *
 */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <time.h>

int
main(void)
{
    FILE *fd;
    char *line = NULL;
    char input_file[] = "/var/log/httpd/access_log";
    size_t len = 0;
    ssize_t read;
    long file_position = 0;
    int line_count = 0;
    int host_length = 32;
    int sockfd;
    struct sockaddr_in server;
    char *graphite_host = "graphite.example.com";
    int graphite_port = 2003;
    char metric[] = "apache.requests_per_second";
    struct hostent *hostentry;
    struct in_addr **addr_list;
    char ip[16];
    time_t epoch;
    char message[100];

    if ((hostentry = gethostbyname(graphite_host)) == NULL) {
        printf("Failed to lookup hostname '%s'\n", graphite_host);
        exit(EXIT_FAILURE);
    }
    addr_list = (struct in_addr **) hostentry->h_addr_list;
     
    // Get the IP address of the Graphite host.
    /*
    int i;
    for(i = 0; addr_list[i] != NULL; i++) {
        //Return the first one;
        strcpy(ip, inet_ntoa(*addr_list[i]) );
    }
    */
    strcpy(ip, inet_ntoa(*addr_list[0]) );
    //printf("%s resolved to: %s\n", graphite_host, ip);
    server.sin_addr.s_addr = inet_addr(ip);
    server.sin_family = AF_INET;
    server.sin_port = htons(graphite_port);

    // We'll use the hostname as part of the metric name.
    //char hostname[32];
    //gethostname(hostname, 32);
    //printf("Hostname is %s\n", hostname);

    fd = fopen(input_file, "r");
    if (fd == NULL) {
        exit(EXIT_FAILURE);
    }

    // Start at the end of the file so we don't see a huge spike on the graphs.
    fseek(fd, 0, SEEK_END);
    while (1) {
        epoch = time(NULL);
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd == -1) {
            printf("Failed to create socket!\n");
        }
        // Connect to Graphite.
        if (connect(sockfd, (struct sockaddr *)&server, sizeof(server)) < 0) {
            printf("Failed to connect to %s:%d\n", graphite_host, graphite_port);
            perror("Failed to connect");
            exit(EXIT_FAILURE);
        }
        //printf("CONNECTED!\n");

        while ((read = getline(&line, &len, fd)) != -1) {
            //file_position = ftell(fd);
            line_count++;
        }
        //printf("Line Count: %d\n", line_count);
        sprintf(message, "%s %d %d\n", metric, line_count, epoch);
        printf(message);
        if(send(sockfd, message, strlen(message), 0) < 0) {
            perror("Failed to send message");
            exit(EXIT_FAILURE);
        }
        line_count = 0;
        close(sockfd);

        if (line) {
            free(line);
            line = NULL;
        }
        //printf("Value of file_position is %d\n", file_position);
        // I thought we'd need to seek to the last part of the file read, but
        // we don't.
        //fseek(fd, file_position, SEEK_SET);

        sleep(1);
    }
    //exit(EXIT_SUCCESS);
}
