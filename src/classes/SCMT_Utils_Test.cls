/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@isTest
private class SCMT_Utils_Test
{

    private static final String CREATED_DATE_TIME = '2010-01-01 01:23:45';
    private static final String LAST_MODIFIED_DATE_TIME = '2015-01-01 12:34:56';
/**/
    @isTest static void AuditFieldsAccount()
    {
        // create account
        Account rec = new Account();

        // set required fields
        rec.Name = 'Desk Audit Fields Test';

        // set desk id indicating it was migrated from desk
        rec.SCMT__DeskId__c = 12345;

        // set the desk created_at and updated_at fields
        rec.SCMT__DeskCreatedAt__c = Datetime.valueOf(CREATED_DATE_TIME);
        rec.SCMT__DeskUpdatedAt__c = Datetime.valueOf(LAST_MODIFIED_DATE_TIME);

        // insert the account
        insert rec;

        // update the account object
        rec = [SELECT SCMT__DeskId__c, SCMT__DeskCreatedAt__c, SCMT__DeskUpdatedAt__c, CreatedDate, LastModifiedDate
            FROM Account
            WHERE Id = :rec.Id];

        // check that the desk id was set
        System.assertEquals(12345, rec.SCMT__DeskId__c);

        // check that the desk created_at and updated_at fields were set
        System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.SCMT__DeskCreatedAt__c);
        System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.SCMT__DeskUpdatedAt__c);

        // check if the audit fields can be set on insert
        if (Schema.sObjectType.Case.fields.CreatedDate.isCreateable())
        {
            // check that the Salesforce CreatedDate and LastModifiedDate audit fields were set
            System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.CreatedDate);
            //System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.LastModifiedDate);
        }
    }
/**/
/**/
    @isTest static void AuditFieldsContact()
    {
        // create account
        Contact rec = new Contact();

        // set required fields
        rec.LastName = 'TEST';

        // set desk id indicating it was migrated from desk
        rec.SCMT__DeskId__c = 12345;

        // set the desk created_at and updated_at fields
        rec.SCMT__DeskCreatedAt__c = Datetime.valueOf(CREATED_DATE_TIME);
        rec.SCMT__DeskUpdatedAt__c = Datetime.valueOf(LAST_MODIFIED_DATE_TIME);

        // insert the account
        insert rec;

        // update the account object
        rec = [SELECT SCMT__DeskId__c, SCMT__DeskCreatedAt__c, SCMT__DeskUpdatedAt__c, CreatedDate, LastModifiedDate
            FROM Contact
            WHERE Id = :rec.Id];

        // check that the desk id was set
        System.assertEquals(12345, rec.SCMT__DeskId__c);

        // check that the desk created_at and updated_at fields were set
        System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.SCMT__DeskCreatedAt__c);
        System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.SCMT__DeskUpdatedAt__c);

        // check if the audit fields can be set on insert
        if (Schema.sObjectType.Case.fields.CreatedDate.isCreateable())
        {
            // check that the Salesforce CreatedDate and LastModifiedDate audit fields were set
            System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.CreatedDate);
            //System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.LastModifiedDate);
        }
    }
/**/
/**/
    @isTest static void AuditFieldsCase()
    {
        // create account
        Case rec = new Case();

        // set required fields

        // set desk id indicating it was migrated from desk
        rec.SCMT__DeskId__c = 12345;

        // set the desk created_at and updated_at fields
        rec.SCMT__DeskCreatedAt__c = Datetime.valueOf(CREATED_DATE_TIME);
        rec.SCMT__DeskUpdatedAt__c = Datetime.valueOf(LAST_MODIFIED_DATE_TIME);

        // insert the account
        insert rec;

        // update the account object
        rec = [SELECT SCMT__DeskId__c, SCMT__DeskCreatedAt__c, SCMT__DeskUpdatedAt__c, CreatedDate, LastModifiedDate
            FROM Case
            WHERE Id = :rec.Id];

        // check that the desk id was set
        System.assertEquals(12345, rec.SCMT__DeskId__c);

        // check that the desk created_at and updated_at fields were set
        System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.SCMT__DeskCreatedAt__c);
        System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.SCMT__DeskUpdatedAt__c);

        // check if the audit fields can be set on insert
        if (Schema.sObjectType.Case.fields.CreatedDate.isCreateable())
        {
            // check that the Salesforce CreatedDate and LastModifiedDate audit fields were set
            System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.CreatedDate);
            //System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.LastModifiedDate);
        }
    }
/**/
/**/
    @isTest static void AuditFieldsCaseUpdatedOlderThanCreated()
    {
        // create account
        Case rec = new Case();

        // set required fields

        // set desk id indicating it was migrated from desk
        rec.SCMT__DeskId__c = 12345;

        // set the desk created_at and updated_at fields
        rec.SCMT__DeskCreatedAt__c = Datetime.valueOf(LAST_MODIFIED_DATE_TIME);
        rec.SCMT__DeskUpdatedAt__c = Datetime.valueOf(CREATED_DATE_TIME);

        // insert the account
        insert rec;

        // update the account object
        rec = [SELECT SCMT__DeskId__c, SCMT__DeskCreatedAt__c, SCMT__DeskUpdatedAt__c, CreatedDate, LastModifiedDate
            FROM Case
            WHERE Id = :rec.Id];

        // check that the desk id was set
        System.assertEquals(12345, rec.SCMT__DeskId__c);

        // check that the desk created_at and updated_at fields were set
        System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.SCMT__DeskCreatedAt__c);
        System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.SCMT__DeskUpdatedAt__c);

        // check if the audit fields can be set on insert
        if (Schema.sObjectType.Case.fields.CreatedDate.isCreateable())
        {
            // check that the Salesforce CreatedDate and LastModifiedDate audit fields were set
            System.assertEquals(Datetime.valueOf(LAST_MODIFIED_DATE_TIME), rec.CreatedDate);
            //System.assertEquals(Datetime.valueOf(CREATED_DATE_TIME), rec.LastModifiedDate);
        }
    }
/**/
}