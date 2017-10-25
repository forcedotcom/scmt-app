/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

public class MigrationWizardController {

    private static final User CURRENT_USER = [Select UserPermissionsKnowledgeUser, UserPermissionsSupportUser FROM User WHERE Id =: UserInfo.getUserId()];
    private static final Profile CURRENT_PROFILE = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
    private static final Desk_Config__mdt CONFIG = [SELECT ID, Host__c, Endpoint__c, ConsumerKey__c, ConsumerSecret__c, Token__c, TokenSecret__c FROM Desk_Config__mdt WHERE Active__c = true LIMIT 1];

    @AuraEnabled
    public static Map<String, Object> config() {
        Map<String, Object> c = new Map<String, Object>();

        c.put('privateServerUrl', CONFIG.Host__c);

        c.put('privateSessionId', getSessionId());
        c.put('privateUserEmail', UserInfo.getUserEmail());
        c.put('privateApiUrl', URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/36.0/' + UserInfo.getOrganizationId());

        c.put('privateAuditEnabled', Schema.sObjectType.Case.fields.CreatedDate.isCreateable());
        c.put('privateProfiles', [SELECT Id, Name FROM Profile WHERE UserLicense.Name LIKE 'Salesforce' ORDER BY Name]);
        c.put('privateRecordTypes', [SELECT Id, Name, SObjectType FROM RecordType WHERE SObjectType IN ('Account', 'Contact', 'Case')]);

        c.put('privateDeskEndpoint', CONFIG.Endpoint__c);
        c.put('privateDeskConsumerKey', CONFIG.ConsumerKey__c);
        c.put('privateDeskConsumerSecret', CONFIG.ConsumerSecret__c);
        c.put('privateDeskToken', CONFIG.Token__c);
        c.put('privateDeskTokenSecret', CONFIG.TokenSecret__c);

        return c;
    }

    @AuraEnabled
    public static List<Desk_Migration__c> fetchMigrationObjects() {
        List<Desk_Migration__c> migs = [SELECT Name, StartDate__c, Status__c, RecordsMigrated__c, RecordsFailed__c, JobId__c, Object__c FROM Desk_Migration__c ORDER BY CreatedDate DESC];
        return migs;
    }

    @AuraEnabled
    public static String createMigrationRecord(String name) {
        Desk_Migration__c dm = new Desk_Migration__c(Object__c = name, Status__c = 'New', StartDate__c = DateTime.now());
        Database.insert(dm);
        return dm.Id;
    }

    @AuraEnabled
    public static Map<String, Object> fetchSalesforceMetadata(Map<String, Object> deskData) {
        List<Object> deskGroups = (List<Object>) deskData.get('groups');
        Map<String, Group> sfdcGroups = groups();
        for (Object g : deskGroups) {
            Map<Object, Object> gr = (Map<Object, Object>) g;
            if (sfdcGroups.containsKey('Desk_' + String.valueOf(gr.get('id')))) {
                gr.put('salesforce', sfdcGroups.get('Desk_' + String.valueOf(gr.get('id'))));
            }
        }

        List<Group> groupsList = new list<Group>();
        for (Group g : sfdcGroups.values()) {
            groupsList.add(g);
        }

        List<Object> deskUsers = (List<Object>) deskData.get('users');
        Map<String, User> sfdcUsers = users();
        for (Object u : deskUsers) {
            Map<Object, Object> ur = (Map<Object, Object>) u;
            if (sfdcUsers.containsKey(String.valueOf(ur.get('email')))) {
                ur.put('salesforce', sfdcUsers.get(String.valueOf(ur.get('email'))));
            }
        }

        List<User> usersList = new list<User>();
        for (User u : sfdcUsers.values()) {
            usersList.add(u);
        }

        List<Object> deskCustomFields = (List<Object>) deskData.get('custom_fields');
        Map<String, Map<String, Schema.DescribeFieldResult>> sfdcCustomFields = customFields();
        for (Object c : deskCustomFields) {
            Map<Object, Object> cr = (Map<Object, Object>) c;
            String key = 'Desk_' + String.valueOf(cr.get('name')) + '__c';
            String type = String.valueOf(cr.get('type'));

            if (sfdcCustomFields.containsKey(type) && sfdcCustomFields.get(type).containsKey(key.toLowerCase())) {
                cr.put('salesforce', new CustomField(type, sfdcCustomFields.get(type).get(key.toLowerCase())));
            }
        }


        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('desk_groups', deskGroups);
        metadata.put('desk_users', deskUsers);
        metadata.put('desk_custom_fields', deskCustomFields);
        metadata.put('sfdc_groups', groupsList);
        metadata.put('sfdc_users', usersList);

        return metadata;
    }

    @AuraEnabled
    public static List<CheckItem> checklist() {
        List<CheckItem> checks = new List<CheckItem>();
        // Service Cloud
        checks.add(new CheckItem('System Administrator', (CURRENT_PROFILE.Name == 'System Administrator'), true));
        checks.add(new CheckItem('Service Cloud User Permission', CURRENT_USER.UserPermissionsSupportUser, true));

        // Set Audit Fields upon Record Creation
        // Update Records with Inactive Owners
        checks.add(new CheckItem(
                '`Set Audit Fields upon Record Creation` Enabled',
                Schema.sObjectType.Case.fields.CreatedDate.isCreateable(),
                false
        ));

        // Live Agent Enabled
        checks.add(new CheckItem('Live Agent Enabled', Schema.getGlobalDescribe().containsKey('LiveAgentSession'), false));

        // Knowledge User
        checks.add(new CheckItem('Knowledge User Permission', CURRENT_USER.UserPermissionsKnowledgeUser, false));

        return checks;
    }

    public static Map<String, Group> groups() {
        Map<String, Group> sfdcGroups = new Map<String, Group>();
        for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue']) {
            sfdcGroups.put(g.DeveloperName, g);
        }
        return sfdcGroups;
    }

    public static Map<String, User> users() {
        Map<String, User> sfdcUsers = new Map<String, User>();
        for (User u : [SELECT Id, Name, Email, IsActive FROM User]) {
            sfdcUsers.put(u.Email, u);
        }
        return sfdcUsers;
    }

    public static Map<String, Map<String, Schema.DescribeFieldResult>> customFields() {
        Map<String, Map<String, Schema.DescribeFieldResult>> cf = new Map<String, Map<String, Schema.DescribeFieldResult>>();

        cf.put('company', new Map<String, Schema.DescribeFieldResult>());
        for (String field : Schema.SObjectType.Account.fields.getMap().keySet()) {
            cf.get('company').put(field, Schema.SObjectType.Account.fields.getMap().get(field).getDescribe());
        }

        cf.put('customer', new Map<String, Schema.DescribeFieldResult>());
        for (String field : Schema.SObjectType.Contact.fields.getMap().keySet()) {
            cf.get('customer').put(field, Schema.SObjectType.Contact.fields.getMap().get(field).getDescribe());
        }

        cf.put('ticket', new Map<String, Schema.DescribeFieldResult>());
        for (String field : Schema.SObjectType.Case.fields.getMap().keySet()) {
            cf.get('ticket').put(field, Schema.SObjectType.Case.fields.getMap().get(field).getDescribe());
        }

        return cf;
    }

    public static String getSessionId() {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(Page.SessionId.getContent().toString());
        return (String) m.get('sessionId');
    }

    public class CheckItem {
        @AuraEnabled
        public String variant { get; private set; }
        @AuraEnabled
        public String label { get; private set; }

        public CheckItem(String label, Boolean passed, Boolean required) {
            this.label = label;
            if (!required) this.label = this.label + ' (Optional)';
            if (passed) this.variant = 'success';
            else {
                if (required) this.variant = 'error';
                else this.variant = 'warning';
            }
        }
    }

    public class CustomField {
        @AuraEnabled
        public String name { get; private set; }
        @AuraEnabled
        public String label { get; private set; }
        @AuraEnabled
        public String type { get; private set; }
        @AuraEnabled
        public Boolean active { get; private set; }
        @AuraEnabled
        public Map<String, Object> data { get; private set; }

        public CustomField(String type, Schema.DescribeFieldResult dfr) {
            this.name   = dfr.getName();
            this.label  = dfr.getLabel();
            this.type   = type;
            this.active = true;

            this.data = new Map<String, Object>();
            this.data.put('type', this.getType(dfr.getType()));

            if (Schema.DisplayType.PICKLIST === dfr.getType()) {
                List<String> choices = new List<String>();
                for (Schema.PicklistEntry e : dfr.getPicklistValues()) {
                    if (e.isActive()) {
                        choices.add(e.getValue());
                    }
                }
                this.data.put('choices', choices);
            }
        }

        public String getType(Schema.DisplayType type) {
            if (Schema.DisplayType.BOOLEAN === type) return 'boolean';
            if (Schema.DisplayType.INTEGER === type) return 'integer';
            if (Schema.DisplayType.PICKLIST === type) return 'list';
            if (Schema.DisplayType.DATE === type || Schema.DisplayType.DATETIME === type || Schema.DisplayType.TIME === type)
                return 'date';
            return 'string';
        }

    }

}