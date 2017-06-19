/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@isTest
public with sharing class Test_DeskMigrationWizardController {
    static testmethod void Test_DeskMigrationWizardController() {

        DeskMigrationWizardController con = new DeskMigrationWizardController();
        con.jsonData = '{ "groups":["A-Team","Adrenaline Junkies"], "brands": ["Aloha Adventures", "Aloha Guide Services"], "custom_fields": [{ "name": "my_trip_date", "label": "Trip Date", "type": "customer", "active": false, "data": { "type": "date" } }, { "name": "my_fav_island", "label": "Favorite Hawaiian Island", "type": "customer", "active": true, "data": { "type": "list", "choices": ["Hawaii", "Kauaii", "Lanai", "Maui", "Oahu"] } }, { "name": "my_trip_ct", "label": "Previous Trip Count", "type": "customer", "active": true, "data": { "type": "integer" } }, { "name": "my_vip", "label": "VIP Customer", "type": "customer", "active": true, "data": { "type": "boolean" } }, { "name": "my_password", "label": "Password", "type": "ticket", "active": false, "data": { "type": "string" } }, { "name": "custom_case_number", "label": "Custom Case Number", "type": "ticket", "active": false, "data": { "type": "integer" } }, { "name": "test_csat", "label": "Test CSAT", "type": "ticket", "active": true, "data": { "type": "string" } }, { "name": "mobile_os", "label": "Mobile OS", "type": "ticket", "active": true, "data": { "type": "list", "choices": ["Android", "Atari", "Blackberry", "iOS", "Windows Phone"] } }, { "name": "travel_date", "label": "Travel Date", "type": "ticket", "active": true, "data": { "type": "date" } }, { "name": "count_case", "label": "Case_Count", "type": "ticket", "active": true, "data": { "type": "integer" } }, { "name": "case_last_hour", "label": "Case_Last_Hour", "type": "ticket", "active": true, "data": { "type": "boolean" } }, { "name": "url", "label": "URL", "type": "ticket", "active": true, "data": { "type": "string" } }, { "name": "ews", "label": "EWS", "type": "ticket", "active": true, "data": { "type": "string" } }, { "name": "third_party_info", "label": "Booking ID", "type": "ticket", "active": true, "data": { "type": "string" } }, { "name": "case_timer", "label": "Case Timer", "type": "ticket", "active": true, "data": { "type": "integer" } }, { "name": "my_deadline", "label": "Deadline", "type": "ticket", "active": true, "data": { "type": "date" } }, { "name": "activity_island", "label": "Activity Island", "type": "ticket", "active": true, "data": { "type": "list", "choices": ["Hawaii", "Kauaii", "Maui", "Molokai", "Oahu", "Lanai"] } }, { "name": "activity", "label": "Activity", "type": "ticket", "active": true, "data": { "type": "list", "choices": ["High Speed Vespa", "Lava Surfing", "SCUBA Diving", "Skydiving", "Riding Sharks", "Swimming with Giant Squid", "Volcano Diving"] } }, { "name": "activity_level", "label": "Activity Level", "type": "ticket", "active": true, "data": { "type": "list", "choices": ["As Easy as its Going to Get Here", "Not Boring, Not Life Threatening", "Extreme", "Off the Fn Hook"] } }], "languages": { "ar": { "id": "ar", "name": "Arabic", "salesforce_code": "ar", "supported": "true" }, "ca": { "id": "ca", "name": "Catalan", "supported": "false" }, "cs": { "id": "cs", "name": "Czech", "salesforce_code": "cs", "supported": "true" }, "da": { "id": "da", "name": "Danish", "salesforce_code": "da", "supported": "true" } }, "topics": [] }';
        
      

        PageReference ref1 = con.navToMigrationStatus();
        System.assertEquals(null,  ref1);

        DeskMigrationWizardController.createMigrationStatusRemote();
        

        con.getMigrationLanguages();
        System.assertNotEquals(null, con.getLanguagesToMigrateCount());

        con.getMigrationCustomFields();
        System.assertNotEquals(null, con.getNewCustomFieldsCount());
        
        con.getMigrationTopicsAndBrands();
        System.assertNotEquals(null, con.getNewTopicsAndBrandsCount());

        con.getMigrationGroups();
        System.assertNotEquals(null, con.getNewGroupsCount());

        DeskMigrationWizardController.DeskLanguage language = new DeskMigrationWizardController.DeskLanguage('id', 'english', 'en_US', true);
        DeskMigrationWizardController.DeskCustomField field = new DeskMigrationWizardController.DeskCustomField('name', 'label', 'parent', true, 'type', 'other', true);
        
        con.errorLevel = 'CONFIRM';
        con.messageName = 'Test';
        con.messageDetail = 'Test';
        con.showMessage();
        con.clearMessages();

        String fields = con.getObjectFieldsJSON();
        System.assertNotEquals(null, fields);

        String sandbox = con.getIsSandbox();
        System.assertNotEquals(null, sandbox);

        con.moveStartMonthForward();
        con.refreshJSON();
        con.getPreFlightChecks();

        String json ='';
        DeskMigrationWizardController.getCustomFieldsAndGroups(con.jsonData);
        DeskMigrationWizardController.getMigrationCustomFieldsRemote(con.jsonData);
        DeskMigrationWizardController.getMigrationGroupsRemote(con.jsonData);

        PageReference  ref = con.moveStartMonthBackward();

    }
}