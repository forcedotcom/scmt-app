# Service Cloud Migration Tool - Package

Migrate your data from your Desk.com org to your Service Cloud org.

## Supported Data
* Users
* Queues (Groups & Memberships)
* Articles (primary language only)
* Accounts (Companies)
* Contacts (Customers)
* Cases & Attachments
* Custom Fields and Labels

[Setup Instructions / FAQ](https://appexchange.salesforce.com/servlet/servlet.FileDownload?file=00P3A00000WIcRGUA1)


## Force.com CLI Deployment
1. Download and install [Force.com CLI](https://force-cli.heroku.com/)
2. Login to your Org `$ force login`
3. Navigate into your clone `$ cd scmt-app`
4. Import to your Org `$ force import -r -v -d ./src`
