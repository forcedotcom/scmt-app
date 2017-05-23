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
        if (typeof params === 'function') {
            background = callback;
            callback   = params;
            params     = {};
        }

        cmp.loading(background);
        var action = cmp.get(name);

        action.setParams(params);
        action.setCallback(this, function(res) {
            cmp.loading(background);

            var state = res.getState();
            if (cmp.isValid() && state === 'SUCCESS') {
                callback(res);
            } else if (cmp.isValid() && state === 'ERROR') {
                var errors = res.getError();

                if (errors && errors[0]) {
                    errors = errors[0];
                    if (errors['pageErrors'] && errors['pageErrors'][0]) {
                        console.log('Error message: ' + errors['pageErrors'][0].message);
                        return cmp.alert(errors['pageErrors'][0].message);
                    }
                }

                console.log('Unknown error');
                console.log(res, res.getError());
                cmp.alert('Unknown Error');
            }
        });
        $A.enqueueAction(action);
    },

    createMetadata: function(cmp) {
        var data = {
            custom_fields: JSON.stringify(cmp.get('v.privateCustomFields').filter(function(el) { return !el.hasOwnProperty('salesforce') })),
            groups: JSON.stringify(cmp.get('v.privateGroups').filter(function(el) { return !el.hasOwnProperty('salesforce') }).map(function(el) { return [el.id.toString(), 'false'] })),
            users: JSON.stringify(cmp.get('v.privateUsers').filter(function(el) { return !el.hasOwnProperty('salesforce') }))
        };

        this.request(cmp, '/desk/MigrateMetadata', data, function(data, status) {
            cmp.find('migrationwizard').next(true);
        });
    },

    convertTimestamp: function(migrations) {
        return migrations.map(function(el) {
            el.StartDate__c = new Date(el.StartDate__c);
            return el;
        });
    },

    fetchMigrationObjects: function(cmp, background) {
        var helper = this;
        helper.callApex(cmp, 'c.fetchMigrationObjects', function(rsp) {
            var objects = {};

            Array.from(rsp.getReturnValue()).forEach(function(el) {
                objects[el.Object__c] = objects[el.Object__c] || [];
                objects[el.Object__c].push(el);
            });

            for (var key in objects) {
                cmp.set('v.private' + key.replace(/\s/g,'') + 'Objects', helper.convertTimestamp(objects[key]));
            }
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
        }).fail(function(data, status, err) {
            cmp.alert(err.message);
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