/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

trigger SCMT_AuditFieldsAccount on Account(before insert)
{
    if (Schema.sObjectType.Account.fields.CreatedDate.isCreateable())
    {
        SCMT_Utils utils = new SCMT_Utils();
        utils.UpdateAuditFields();
    }
}