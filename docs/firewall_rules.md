# Firewall Rules Documentation

## Overview

Micro-segmentation implemented using pfSense to enforce Zero Trust Network principles and prevent lateral movement between VLANs.

## VLAN Architecture

| VLAN   | Name           | Subnet          |
| ------ | -------------- | --------------- |
| VLAN10 | Production     | 192.168.10.0/24 |
| VLAN20 | Management     | 192.168.20.0/24 |
| VLAN30 | DMZ / Honeypot | 192.168.30.0/24 |

## Firewall Rule Matrix

| Source      | Destination                  | Port / Protocol | Action | Purpose                                                |
| ----------- | ---------------------------- | --------------- | ------ | ------------------------------------------------------ |
| VLAN10_PROD | WAZUH_SERVER (192.168.20.10) | TCP 1514        | PASS   | Wazuh Agent Communication                              |
| VLAN10_PROD | VLAN20_MGMT                  | ANY             | BLOCK  | Prevent lateral movement from Production to Management |
| VLAN10_PROD | VLAN30_DMZ                   | ANY             | PASS   | Honeypot simulation traffic                            |
| VLAN30_DMZ  | WAZUH_SERVER (192.168.20.10) | TCP 1514        | PASS   | Honeypot log forwarding                                |
| VLAN30_DMZ  | VLAN20_MGMT                  | ANY             | BLOCK  | Restrict access to Management network                  |
| VLAN30_DMZ  | VLAN10_PROD                  | ANY             | BLOCK  | Prevent DMZ-to-Production movement                     |
| VLAN30_DMZ  | Internet                     | ANY             | PASS   | Internet connectivity                                  |

## Validation Results

| Test Case                 | Expected Result | Actual Result |
| ------------------------- | --------------- | ------------- |
| VLAN10 → VLAN20 ICMP      | Blocked         | PASS          |
| VLAN10 → VLAN20 SMB (445) | Blocked         | PASS          |
| Wazuh Agent Connectivity  | Active          | PASS          |
| Honeypot Log Forwarding   | Active          | PASS          |
