#!/bin/python3
import requests as req, string, re, random
from requests.auth import HTTPBasicAuth

file = open('/home/user/git/maintenance/nexus-user-add-users.txt', 'r')
for line in file:
    currentline = line.split(" ")
    currentlogin = re.sub('@.*', '', currentline[0])
    currentpasswds = currentline[4].replace('\n', '')
    currentjson = {
    'userId': currentlogin,
    'firstName': currentline[1],
    'lastName': currentline[2],
    'emailAddress': currentline[0],
    'password': currentpasswds,
    'status': 'active',
    'roles': [currentline[3]] 
    }
    response = req.post(
        'http://11.22.33.44/service/rest/v1/security/users',
        auth=HTTPBasicAuth('USER', 'PASSWD'),
        json=currentjson,
        headers={
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })
    print(response.status_code, response.text)
file.close