

Favorite Command

	$ vagrant ssh control
	$ cd /home/vagrant
	$ source devstack/openrc
	$ openstack image list



	source ~/devstack/openrc admin admin

## get token ##
curl -i -H "Content-Type: application/json" -d '{"auth": {"identity":{"methods":["password"],"password":{"user":{"name":"admin","domain":{"id":"default" },"password":"admin"}}},"scope":{"project":{"name":"demo","domain":{"id":"default"}}}}}' "http://192.168.0.10/identity/v3/auth/tokens" 2>&1 | grep X-Subject-Token | sed "s/^.*: //"

## use token

curl -s -H "X-Auth-Token:gAAAAABZ7qm-V4PKGe-ww3kfGbPq9rVZNyGFwgj4Y95Bq5Q8lKEKQZSrEuO2f9H-egIy22GyesVDoRl4n6TPwGA_Zm0Fc3DcYPaNMWGviyWNMu8bUBb43Um1WUk-VWxHu3Tg0mfZNlQ-pP3end5QBzZRztK3kp7cXrUF45gcr9aGIo4PlSDt1-A" "http://192.168.0.10/identity/v3/endpoints"