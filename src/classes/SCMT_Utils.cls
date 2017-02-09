/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

public class SCMT_Utils
{
    // This method is intended to be called from a trigger and will set the audit fields before the record is created.
    public void UpdateAuditFields()
    {
        // ensure the trigger is 'before insert'
        if (Trigger.isBefore && Trigger.isInsert)
        {
            // loop through the 'new' records
            for (SObject so : Trigger.new)
            {
                // check if the 'DeskId' is set, if so this is a case migrated from Desk.com
                if (so.get('SCMT__DeskId__c') != null)
                {
                    // get the Desk Created/Updated At values into Datetime variables
                    Datetime deskCreatedAt = (Datetime) so.get('SCMT__DeskCreatedAt__c');
                    Datetime deskUpdatedAt = (Datetime) so.get('SCMT__DeskUpdatedAt__c');

                    System.debug('CreatedDate: [' + so.get('CreatedDate') + '] => [' + deskCreatedAt + ']\n' +
                        'LastModifiedDate: [' + so.get('LastModifiedDate') + '] => [' +
                        (deskCreatedAt <= deskUpdatedAt ? deskUpdatedAt : deskCreatedAt) + ']');

                    // put the Desk.com created_at and updated_at values into the Salesforce CreatedDate and LastModifiedDate
                    so.put('CreatedDate', deskCreatedAt);

                    // Salesforce does not allow the LastModifiedDate to be older than the CreatedDate,
                    // if the DeskUpdatedAt is older than DeskCreatedAt, use DeskCreatedAt
                    so.put('LastModifiedDate', (deskCreatedAt <= deskUpdatedAt ? deskUpdatedAt : deskCreatedAt));
                }
            }
        }
    }
}