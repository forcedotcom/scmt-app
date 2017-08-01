/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({
    init: function(cmp, evt, helper) {
        helper.callApex(cmp, 'c.checklist', function(rsp) {
            var checks = rsp.getReturnValue();
            cmp.set('v.privateChecks', checks);

            if (checks.filter(function(el) { return el.variant === 'error'; }).length > 0) {
                cmp.find('migrationwizard').set('v.hasNextButton', false);
            }
        });

        helper.callApex(cmp, 'c.config', function(rsp) {
            var config = rsp.getReturnValue();
            for (var k in config) {
                if (config.hasOwnProperty(k)) {
                    cmp.set('v.' + k, config[k]);
                }
            }
        });
    },

    handleBlur: function(cmp, evt, helper) {
        var allValid = cmp.find('auth').reduce(function(valid, el) {
            return valid && el.get('v.validity').valid;
        });
        cmp.find('migrationwizard').set('v.hasNextButton', allValid);
    },

    handleConnect: function(cmp, evt, helper) {
        helper.request(cmp, '/desk/AuthenticateTokens', function(data, status) {
            cmp.find('migrationwizard').next(true);
        });
        return false;
    },

    fetchMetadata: function(cmp, evt, helper) {
        helper.request(cmp, '/desk/retrieveMetadata', function(data, status) {
            cmp.processMetadata(data);
        });
    },

    handleMetadata: function(cmp, evt, helper) {
        helper.createMetadata(cmp);
        return false;
    },

    processMetadata: function(cmp, evt, helper) {
        var data = (evt.getParam('arguments') || {}).data;

        helper.callApex(cmp, 'c.fetchSalesforceMetadata', { deskData: data }, function(rsp) {
            var sfdc = rsp.getReturnValue();
            cmp.set('v.privateGroups', sfdc.desk_groups);
            cmp.set('v.privateUsers', sfdc.desk_users);
            cmp.set('v.privateCustomFields', sfdc.desk_custom_fields);
            cmp.set('v.privateSelectGroups', sfdc.sfdc_groups);
            cmp.set('v.privateSelectUsers', sfdc.sfdc_users);
        });
    },

    showAlert: function(cmp, evt, helper) {
        var message = (evt.getParam('arguments') || {}).message;
        cmp.set('v.privateToastMessage', message);
        $A.util.toggleClass(cmp.find('toast'), 'slds-hide');
    },

    toggleLoading: function(cmp, evt, helper) {
        var background = (evt.getParam('arguments') || {}).background
          , loadingId  = background ? 'background-loading' : 'loading';

        cmp.set('v.privateMigrationButtonDisabled', !cmp.get('v.privateMigrationButtonDisabled'));
        $A.util.toggleClass(cmp.find(loadingId), 'slds-hide');
    },

    reloadObjects: function(cmp, evt, helper) {
        helper.fetchMigrationObjects(cmp, true);
    },

    fetchObjects: function(cmp, evt, helper) {
        helper.fetchMigrationObjects(cmp);
        setInterval(cmp.reloadObjects, 15000);
    },

    createMigration: function(cmp, evt, helper) {
        var name  = cmp.get('v.privateActiveObject')
          , valid = cmp.find(name + 'Input') && cmp.find(name + 'Input').reduce(function(v, i) {
              if (i.get('v.validity'))
                  return v && i.get('v.validity').valid;
              return v;
          }, true);

        if (valid === false)
            return cmp.alert('Please update the invalid form entries and try again.');

        // create migration in apex
        name = name.slice(0, -1);

        helper.callApex(cmp, 'c.createMigrationRecord', { name: name }, function(rsp) {
            var data = {
                updated_at: helper.getUpdatedAt(name, cmp),
                start_id: helper.getStartId(name, cmp),
                desk_migration_id: rsp.getReturnValue(),
                auditEnabled: cmp.get('v.privateAuditEnabled'),
                ProfileId: cmp.get('v.privateUserProfile'),
                appendTimestamp: cmp.get('v.privateUserTimestamp'),
                account_record_type_id: cmp.get('v.privateAccountRecordType'),
                contact_record_type_id: cmp.get('v.privateContactRecordType'),
                case_record_type_id: cmp.get('v.privateCaseRecordType'),
                migrateUsers: (name === 'User'),
                migrateCompanies: (name === 'Account'),
                migrateCustomers: (name === 'Contact'),
                migrateCases: (name === 'Case'),
                migrateNotes: (name === 'Note'),
                migrateInteractions: (name === 'Interaction'),
                migrateAttachments: (name === 'Attachment'),
                migrateArticles: (name === 'Article'),
                migrateGroupMembers: (name === 'Group Member')
            };

            var url = data.migrateAttachments ? '/desk/MigrateAttachments' : '/desk/MigrateData';
            helper.request(cmp, url, data, function(ret, status) {
                helper.fetchMigrationObjects(cmp, name, true);
            });
        });
    },

    changeObject: function(cmp, evt, helper) {
        try {
            var objects = cmp.get('v.privateObjects')
              , name    = evt.target.dataset.name

            if (name) cmp.set('v.privateActiveObject', name);
        } catch(err) {}
    },

    toggleToast: function(cmp, evt, helper) {
        $A.util.toggleClass(cmp.find('toast'), 'slds-hide');
    },

    jsLoaded: function() {}
})