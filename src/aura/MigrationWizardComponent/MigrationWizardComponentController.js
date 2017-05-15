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
            cmp.set('v.privateGroups', sfdc.groups);
            cmp.set('v.privateUsers', sfdc.users);
            cmp.set('v.privateCustomFields', sfdc.custom_fields);
        });
    },

    showAlert: function(cmp, evt, helper) {
        var message = (evt.getParam('arguments') || {}).message;
        cmp.set('v.privateToastMessage', message);
        $A.util.toggleClass(cmp.find('toast'), 'slds-hide');
    },

    toggleLoading: function(cmp, evt, helper) {
        console.log('loading');
        var background = (evt.getParam('arguments') || {}).background
          , loadingId  = background ? 'background-loading' : 'loading';

        $A.util.toggleClass(cmp.find(loadingId), 'slds-hide');
    },

    reloadObjects: function(cmp, evt, helper) {
        var objects = cmp.get('v.privateObjects')
          , name    = objects.find(function(el) { return el.isActive }).name;

        helper.fetchMigrationObjects(cmp, name, true);
    },

    fetchObjects: function(cmp, evt, helper) {
        helper.fetchMigrationObjects(cmp, 'User');
        setInterval(cmp.reloadObjects, 15000);
    },

    createMigration: function(cmp, evt, helper) {
        // create migration in apex
        var objects = cmp.get('v.privateObjects')
          , name    = objects.find(function(el) { return el.isActive }).name;

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
              , actIdx  = objects.findIndex(function(el) { return el.isActive })
              , newIdx  = objects.findIndex(function(el) { return el.name === evt.target.dataset.name })

            if (Number.isInteger(actIdx) && Number.isInteger(newIdx)) {
                objects[actIdx].isActive = false;
                objects[newIdx].isActive = true;
                cmp.set('v.privateObjects', objects);
            }
        } catch(err) {}
    },

    toggleToast: function(cmp, evt, helper) {
        $A.util.toggleClass(cmp.find('toast'), 'slds-hide');
    },

    jsLoaded: function() {}
})