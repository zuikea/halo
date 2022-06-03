grep "${1}" gradle.properties | cut -d'=' -f2 | sed 's/\r//'
