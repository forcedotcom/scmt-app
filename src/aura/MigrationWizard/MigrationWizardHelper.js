/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    resolveUrl: function(cmp, url) {
        var base = cmp.get('v.privateServerUrl');
        return base + url;
    },

    callApex: function(cmp, name, params, callback, background) {
        cmp.loading(background);
        var action = cmp.get(name);

        if (typeof params === 'function') {
            callback = params;
            params = {};
        }

        action.setParams(params);
        action.setCallback(this, function(res) {
            cmp.loading(background);

            var state = res.getState();
            if (cmp.isValid() && state === 'SUCCESS') {
                callback(res);
            } else if (cmp.isValid() && state === 'ERROR') {
                var errors = res.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.log('Error message: ' + errors[0].message);
                    cmp.set('v.privateMessage', errors[0].message);
                } else {
                    console.log('Unknown error');
                    cmp.set('v.privateMessage', 'Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },

    createMetadata: function(cmp) {
        var data = {
            custom_fields: JSON.stringify(cmp.get('v.privateCustomFields').filter(function(el) { return !el.hasOwnProperty('salesforce') })),
            groups: JSON.stringify(cmp.get('v.privateGroups').filter(function(el) { return !el.hasOwnProperty('salesforce') }).map(function(el) { return [el.id, 'false'] })),
            users: JSON.stringify(cmp.get('v.privateUsers').filter(function(el) { return !el.hasOwnProperty('salesforce') }))
        };

        this.request(cmp, '/desk/MigrateMetadata', data, function(data, status) {
            cmp.find('migrationwizard').next(true);
        });
    },

    convertTimestamp: function(migrations) {
        return migrations.map(function(el) {
            if (el.migrations.length !== 0) {
                el.migrations.map(function(e) {
                    e.StartDate__c = new Date(e.StartDate__c);
                    return e;
                });
            }
            return el;
        });
    },

    fetchMigrationObjects: function(cmp, active, background) {
        var helper = this;
        helper.callApex(cmp, 'c.fetchMigrationObjects', { active: active }, function(rsp) {
            cmp.set('v.privateObjects', helper.convertTimestamp(rsp.getReturnValue()));
        }, background);
    },

    getUpdatedAt: function(name, cmp) {
        if ((cmp.get('v.private' + name + 'DataSet') === '1') && cmp.get('v.private' + name + 'StartDate')) {
            return new Date(cmp.get('v.private' + name + 'StartDate')).getTime();
        }
        return null;
    },

    getStartId: function(name, cmp) {
        if ((cmp.get('v.private' + name + 'DataSet') === '1') && cmp.get('v.private' + name + 'StartId')) {
            return cmp.get('v.private' + name + 'StartId');
        }
        return null;

    },

    salesforceAuth: function(cmp) {
        return {
            user_email: cmp.get('v.privateUserEmail'),
            session_id: cmp.get('v.privateSessionId'),
            server_url: cmp.get('v.privateApiUrl')
        };
    },

    deskAuth: function(cmp) {
        return {
            deskUrl: cmp.get('v.privateDeskEndpoint'),
            consumerKey: cmp.get('v.privateDeskConsumerKey'),
            consumerSecret: cmp.get('v.privateDeskConsumerSecret'),
            accessToken: cmp.get('v.privateDeskToken'),
            accessTokenSecret: cmp.get('v.privateDeskTokenSecret')
        };
    },

    request: function(cmp, url, params, callback) {
        cmp.loading();
        var helper = this;

        if (typeof params === 'function') {
            callback = params;
            params = {};
        }

        params = Object.assign({}, params, this.salesforceAuth(cmp), this.deskAuth(cmp));

        jQuery.ajax({
            type: 'POST',
            url: this.resolveUrl(cmp, url),
            data: params
        }).always(function(data, status) {
            cmp.loading();
            if (status === 'success') {
                callback(data, status);
            } else {
                cmp.alert(data.responseJSON.message);
            }
        });
    }

})