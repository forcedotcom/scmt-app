/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@isTest
public class MigrationWizardControllerTest {

    static testMethod void testConfig() {
        Map<String, Object> config = MigrationWizardController.config();
        System.assert(config.containsKey('privateServerUrl'));
        System.assert(config.containsKey('privateSessionId'));
        System.assert(config.containsKey('privateUserEmail'));
        System.assert(config.containsKey('privateApiUrl'));
        System.assert(config.containsKey('privateAuditEnabled'));
        System.assert(config.containsKey('privateProfiles'));
        System.assert(config.containsKey('privateRecordTypes'));
        System.assert(config.containsKey('privateDeskEndpoint'));
        System.assert(config.containsKey('privateDeskConsumerKey'));
        System.assert(config.containsKey('privateDeskConsumerSecret'));
        System.assert(config.containsKey('privateDeskToken'));
        System.assert(config.containsKey('privateDeskTokenSecret'));
    }
    
    static testMethod void testFetchMigrationObjects() {
        Id dm = MigrationWizardController.createMigrationRecord('Account');
        List<MigrationWizardController.Migration> dms = MigrationWizardController.fetchMigrationObjects();
        System.assertEquals(dm, dms.get(0).Id);
    }
    
    static testMethod void testFetchSalesforceMetadata() {
        Map<String, Object> deskData = new Map<String, Object>();
        deskData.put('groups', new List<Object>());
        deskData.put('users', new List<Object>());
        deskData.put('custom_fields', new List<Object>());
        Map<String, Object> metadata = MigrationWizardController.fetchSalesforceMetadata(deskData);
        System.assert(metadata.containsKey('groups'));
        System.assert(metadata.containsKey('users'));
        System.assert(metadata.containsKey('custom_fields'));
    }

    static testMethod void testChecklist() {
        List<MigrationWizardController.CheckItem> checks = MigrationWizardController.checklist();
        System.assert(checks.size() > 0);
    }
    
    static testMethod void testCustomField() {
        String key = MigrationWizardController.getNamespace().toLowerCase() + 'deskid__c';
        Schema.DescribeFieldResult dfr = Account.getSObjectType().getDescribe().fields.getMap().get(key).getDescribe();
        MigrationWizardController.CustomField cf = new MigrationWizardController.CustomField('company', dfr);
        System.assertEquals(MigrationWizardController.getNamespace() + 'DeskId__c', cf.name);
        System.assertEquals('Desk Id', cf.label);
        System.assertEquals('company', cf.type);
        System.assertEquals(true, cf.active);
    }
}