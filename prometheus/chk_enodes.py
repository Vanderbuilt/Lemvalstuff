import argparse
import re
import socket

# Command-line argument parser
def parse_args():
    parser = argparse.ArgumentParser(description="Check if port 5050 is listening on extracted IPs.")
    parser.add_argument("-f", "--filepath", required=True, help="Path to the text file containing IP addresses or lines with IPs")
    return parser.parse_args()

# Function to extract IPs from a given line
def extract_ip(line):
    ip_pattern = r"\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b"
    match = re.search(ip_pattern, line)
    return match.group(0) if match else None

# Function to check if port 5050 is listening on an IP
def check_port_listening(ip):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(15) # set a 15 second timeout
    result = sock.connect_ex((ip, 5050))
    return not result

# Main function to process the file and report results
def main():
    args = parse_args()
    output_filepath = "enodes-lemon.txt.good"  # Default output filename
    with open(args.filepath, "r") as f_in, open(output_filepath, "a") as f_out:
        for line_num, line in enumerate(f_in.readlines(), start=1):
            ip_address = extract_ip(line)
            if ip_address is None:
                print(f"Line {line_num}: No IP address found.")
                continue

            listening_status = check_port_listening(ip_address)
            if listening_status:
                f_out.write(f"{line}")  # Write to output file
                print(f"IP: {ip_address}, Port 5050: Open (written to {output_filepath})")
            else:
                print(f"IP: {ip_address}, Port 5050: Closed")

if __name__ == "__main__":
    main()
