/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({
    init: function(cmp, evt, helper) {
        helper.computeWizardClassNames(cmp);

        cmp.set('v.privateSteps', helper.getSteps(cmp));
        var currentStep = (helper.getActiveStep(cmp) || helper.getSteps(cmp)[0]);
        cmp.set('v.activeStepId', helper.getStepIndex(currentStep, cmp));
    },

    handleWizardClassNameChange: function(cmp, evt, helper) {
        helper.computeWizardClassNames(cmp);
    },

    handleActiveStepIdChange: function(cmp, evt, helper) {
        var oldStep = helper.getStepByIndex(evt.getParam('oldValue'), cmp);
        if (oldStep) oldStep.set('v.active', false);

        var newStep = helper.getStepByIndex(evt.getParam('value'), cmp);
        cmp.set('v.privateHasBackButton', !!evt.getParam('value'));
        cmp.set('v.hasNextButton', evt.getParam('value') != helper.getSteps(cmp).length - 1);
        cmp.set('v.privateStepLabel', newStep.get('v.label') || 'Step ' + (evt.getParam('value') + 1));
        newStep.set('v.active', true);
    },

    next: function(cmp, evt, helper) {
        var params = evt.getParam('arguments') || {};
        var onnext = helper.getActiveStep(cmp).get('v.onnext');

        function next() {
            var active = cmp.get('v.activeStepId');
            cmp.set('v.activeStepId', ++active);
        }

        if (onnext && params.skipOnNext !== true) {
            onnext.setCallback(this, function(res) {
                if (res.getReturnValue() !== false) next();
            });
            $A.enqueueAction(onnext);
        } else {
            next();
        }
    },

    previous: function(cmp, evt, helper) {
        var active = cmp.get('v.activeStepId');
        cmp.set('v.activeStepId', --active);
    }
})