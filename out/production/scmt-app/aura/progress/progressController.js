/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    init: function(cmp, evt, helper) {
        var items = cmp.get('v.items');
        if (items && items.length > 0)
            cmp.set('v.privateItems', helper.convertItems(items, cmp.get('v.active')));
        cmp.set('v.privateClass', helper.computeClass(cmp.get('v.class'), cmp.get('v.theme')));
        cmp.set('v.privateProgress', helper.computeProgress(cmp.get('v.active'), items.length));
    },

    handleItemsChange: function(cmp, evt, helper) {
        var items = cmp.get('v.items');
        if (items && items.length > 0)
            cmp.set('v.privateItems', helper.convertItems(items, cmp.get('v.active')));
        cmp.set('v.privateProgress', helper.computeProgress(cmp.get('v.active'), items.length));
    },

    handleActiveChange: function(cmp, evt, helper) {
        var items = cmp.get('v.items');
        if (items && items.length > 0)
            cmp.set('v.privateItems', helper.convertItems(items, cmp.get('v.active')));
        cmp.set('v.privateProgress', helper.computeProgress(cmp.get('v.active'), items.length));
    },

    handleClick: function(cmp, evt, helper) {
        cmp.set('v.active', parseInt(evt.currentTarget.dataset.index));
    }

})