#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


#define PERROR(s) do { fprintf(stderr, "%s: ", ARGV0); perror(s); } while (0);


char* ARGV0 = "<ARGV[0] UNKNOWN>";


void update_map(char* map_path, char* map_buffer) {
 size_t map_length = strlen(map_buffer);
 
 int fd;
 if ((fd = open(map_path, O_RDWR)) == -1) {
  PERROR(map_path);
  exit(EXIT_FAILURE);
 }
 if (write(fd, map_buffer, map_length) != map_length) {
  PERROR(map_path);
  exit(EXIT_FAILURE);
 }
 close(fd);
}


void setgroups_deny() {
 const char* setgroups_path = "/proc/self/setgroups";
 const char* setgroups_str = "deny";
 
 int fd;
 if ((fd = open(setgroups_path, O_RDWR)) == -1) {
  if (errno == ENOENT) {
   return;
  } else {
   PERROR(setgroups_path);
   exit(EXIT_FAILURE);
  }
 }
 if (write(fd, setgroups_str, strlen(setgroups_str)) != strlen(setgroups_str)) {
  PERROR(setgroups_path);
  exit(EXIT_FAILURE);
 }
 close(fd);
}


int main(int argc, char *argv[]) {
 ARGV0 = strdup(argv[0]);
 
 char* inner_uid = "";
 char* inner_gid = "";
 int exec_argv_index = 0;
 
 char* argv0_dup = strdup(argv[0]);
 char* prog = basename(argv0_dup);
 if (strncmp(prog, "unroot", sizeof("unroot")) == 0) {
  if (argc < 2) {
   fprintf(stderr, "Usage: %s {command} [arg [...]]\n", argv[0]);
   exit(2);
  }
  inner_uid = "1000";
  inner_gid = "1000";
  exec_argv_index = 1;
 } else {
  if (argc < 4) {
   fprintf(stderr, "Usage: %s {uid} {gid} {command} [arg [...]]\n", argv[0]);
   exit(2);
  }
  inner_uid = argv[1];
  inner_gid = argv[2];
  exec_argv_index = 3;
 }
 
 uid_t outer_uid = getuid();
 gid_t outer_gid = getgid();
 
 if (unshare(CLONE_NEWUSER) == -1) {
  PERROR("unshare");
  exit(EXIT_FAILURE);
 }
 
 const int MAP_BUFFER_SIZE = 128;
 char map_buffer[MAP_BUFFER_SIZE];
 
 snprintf(map_buffer, MAP_BUFFER_SIZE, "%s %ld 1", inner_uid, (long) outer_uid);
 update_map("/proc/self/uid_map", map_buffer);
 
 setgroups_deny();
 
 snprintf(map_buffer, MAP_BUFFER_SIZE, "%s %ld 1", inner_gid, (long) outer_gid);
 update_map("/proc/self/gid_map", map_buffer);
 
 if (execvp(argv[exec_argv_index], &argv[exec_argv_index]) == -1) {
  PERROR("execvp");
  exit(EXIT_FAILURE);
 }
}
