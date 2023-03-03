#!/bin/bash

# Check if subfinder is installed
if ! command -v subfinder &> /dev/null; then
    echo "subfinder could not be found. Please install it first."
    exit
fi

# Check if httprobe is installed
if ! command -v httprobe &> /dev/null; then
    echo "httprobe could not be found. Please install it first."
    exit
fi

# Set the colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get input file path
read -p "Enter path to input file: " input_file

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file not found."
    exit
fi

# Set the number of threads to use
read -p "Enter the number of threads to use (default is 10): " num_threads
if [ -z "$num_threads" ]; then
    num_threads=10
fi

# Loop through domains in input file
while read domain; do
    # Display progress message
    printf "${YELLOW}Processing $domain...${NC}\n"

    # Run subfinder on domain with the specified number of threads
    subdomains=$(subfinder -d $domain -silent -t $num_threads)

    # Use httprobe to check the live status of each subdomain
    live_subdomains=$(echo "$subdomains" | httprobe -c $num_threads)

    # Display the status code for each live subdomain as it is checked
    while read subdomain; do
        status=$(curl -sL -w "%{http_code}" "https://$subdomain" -o /dev/null)
        if [ "$status" -eq "200" ]; then
            printf "${GREEN}$subdomain (status $status)${NC}\n"
        fi
    done <<< "$live_subdomains"

    # Write live subdomains to output file
    output_file="${domain//./_}.txt"
    echo "$live_subdomains" >> "$output_file"

    # Display the number of subdomains found
    num_subdomains=$(wc -l < "$output_file")
    printf "Found ${GREEN}$num_subdomains${NC} live subdomains for ${YELLOW}$domain${NC}\n"
done < "$input_file"

printf "${GREEN}Done.${NC} Results exported to separate files for each domain.\n"
echo "======================================"
# Print script credits
echo "#Ocean-sub-finder by Ocean Academy🐬" 
echo "#Tak.FaNaR"
