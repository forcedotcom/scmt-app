/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

global with sharing class DeskMigrationWizardController
{
    public String confirmImg { get { return '/img/msg_icons/confirm16.png'; } }
    public String warningImg { get { return '/img/msg_icons/warning16.png'; } }
    public String errorImg { get { return '/img/msg_icons/error16.png'; } }

    public String deskUrl { get; set; }
    public String oauthConsumerKey { get; set; }
    public String oauthConsumerSecret { get; set; }
    public String oauthAccessToken { get; set; }
    public String oauthAccessTokenSecret { get; set; }

    public String jsonData { get; set; }
    public String languagesToMigrateJSON { get; private set; }
    private Integer languagesToMigrateCount;
    public String newCustomFieldsJSON { get; private set; }
    private Integer newCustomFieldsCount;
    public String newGroupsJSON { get; private set; }
    private Integer newGroupsCount;
    public String newTopicsAndBrandsJSON { get; private set; }
    private Integer newTopicsAndBrandsCount;
    private List<List<String>> migrationGroups;
    public String herokuServerURL { get; set;}
    public SCMT__Desk_Migration__c deskMigration { get; set; }
    public Date startDate { get; set; } // start date used for migrating data
    public Time startTime { get; set; } //start time used for migrating data
    public Id startRecordId { get; set; } //record Id used for migrating data
    public Id targetProfileId { get; set; } //profile Id used for migrating data
    public Date endDate { get; set; }
    public Time endTime { get; set; }
    public List<WeekWrapper> startWeekWrapperGrid { get; set; }
    public List<WeekWrapper> endWeekWrapperGrid { get; set; }
    public Integer currentStartYear { get; set; }
    public Integer currentStartMonth { get; set; }
    public Integer currentEndYear { get; set; }
    public Integer currentEndMonth { get; set; }
    public List<Integer> years { get; set; }
    public Integer maxYear { get; set; }
    public Integer minYear { get; set; }
    public Date minDate { get; set;}
    public List<SelectOption> yearOptions { get; set;}

    public DeskMigrationWizardController() {
        Map<ID,SCMT__Desk_Config__mdt> desk2SCSettings = new Map<ID,SCMT__Desk_Config__mdt>([SELECT ID, Label, SCMT__URL__c FROM SCMT__Desk_Config__mdt]);
        List<SCMT__Desk_Config__mdt> desk2SCSettingValues =  desk2SCSettings.values();
        if(desk2SCSettingValues.size() == 1)
        {
            // default prod server for package
            herokuServerURL = desk2SCSettingValues[0].SCMT__URL__c;
        }
        else{
            // if there are more than one a test server is being used and it should be labeled as such
            for(SCMT__Desk_Config__mdt s : desk2SCSettingValues)
            {
                if(s.Label == 'test')
                {
                    herokuServerURL = s.SCMT__URL__c;
                }
            }
        }
        
        
        Date referenceStartDate = date.newInstance(2016,4,1);
        startWeekWrapperGrid = initializeDatePickerGrid(referenceStartDate);
        Date referenceEndDate = date.newInstance(2016,5,1);
        endWeekWrapperGrid = initializeDatePickerGrid(referenceEndDate);
        currentStartYear = referenceStartDate.Year();
        currentStartMonth = referenceStartDate.Month();
        currentEndYear = referenceEndDate.Year();
        currentEndMonth = referenceEndDate.Month();
        years = new List<Integer>{2014,2015,2016};
        minYear = 2014;
        maxYear = 2016;
        minDate = date.newInstance(2014,1,1);
        //createMigrationStatus();
        //List<List<String>> groups = getMigrationGroups();
        //system.debug('**** groups from controller constructor ' + groups);
    }

    public List<WeekWrapper> initializeDatePickerGrid(Date referenceDate){
        DateTime referenceDateTime = datetime.newInstance(referenceDate.year(), referenceDate.month(),referenceDate.day());
        Date weekStartDate = referenceDate.toStartofWeek();
        Date monthStartDate = referenceDate.toStartOfMonth();
        String monthStartDay = referenceDateTime.format('EEEE');
        List<WeekWrapper> weekWrapperGrid = new List<WeekWrapper>();
        Integer weekStartIndex = 0;
        List<Integer> month = new List<Integer>();
        List<Date> monthGridDates = new List<Date>();
        Integer noOfDaysInCurrentMonth = date.daysInMonth(referenceDate.year(),referenceDate.month());
        //system.debug('*** ' + monthStartDate + ' ** ' + ' weekStartDate ' + weekStartDate + ' ' +  monthStartDay);
        //system.debug('**** noOfDaysInCurrentMonth ' + noOfDaysInCurrentMonth);
        if(monthStartDay == 'Monday'){
            weekStartIndex = 1;
        }
        else if (monthStartDay == 'Tuesday'){
            weekStartIndex = 2;
        }
        else if (monthStartDay == 'Wednesday'){
            weekStartIndex = 3;
        }
        else if (monthStartDay == 'Thursday'){
            weekStartIndex = 4;
        }
        else if (monthStartDay == 'Friday'){
            weekStartIndex = 5;
        }
        else if (monthStartDay == 'Saturday'){
            weekStartIndex = 6;
        }

        for(integer i=0;i<weekStartIndex;i++){
            Date dt = weekStartDate+i;
            Date d = date.newInstance(dt.year(),dt.month(),dt.day());  
            monthGridDates.add(d);
        }
        for(integer i=0;i<noOfDaysInCurrentMonth;i++){
            Date dt = monthStartDate+i;
            Date d = date.newInstance(dt.year(),dt.month(),dt.day()); 
            monthGridDates.add(d);
        }
        monthGridDates.sort();
        //system.debug('***monthGridDates ' + monthGridDates);
        for(integer i=0;i<5;i++){
            if(i*7 <= noOfDaysInCurrentMonth){
                Date d = monthGridDates[7*i];
                WeekWrapper ww = new WeekWrapper(i,d,referenceDate);
                weekWrapperGrid.add(ww);
            }
        }
        //system.debug('***weekWrapperGrid ' + weekWrapperGrid);
        return weekWrapperGrid;
    }
    

    public PageReference navToMigrationStatus()
    {
        if (deskMigration != null)
        {
            PageReference migrationStatusPage = new PageReference('/' + deskMigration.Id);
            migrationStatusPage.setRedirect(true);
            return migrationStatusPage;
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
            'The creation of the migration status object failed!'));
        return null;
    }

    public String getObjectFieldsJSON()
    {
        // build a map of object to list of fields on that object
        Map<String, Set<String>> objectFields = new Map<String, Set<String>>();
        objectFields.put('company', Schema.SObjectType.Account.fields.getMap().keySet());
        objectFields.put('customer', Schema.SObjectType.Contact.fields.getMap().keySet());
        objectFields.put('ticket', Schema.SObjectType.Case.fields.getMap().keySet());
        return JSON.serialize(objectFields);
    }

    public String getExistingGroupsJSON()
    {
        // get the list of queues
        List<Group> queues = [SELECT DeveloperName FROM Group WHERE Type = 'Queue'];

        // loop through the queues and build a set of queue names
        Set<String> queueNames = new Set<String>();
        for (Group queue : queues)
        {
            queueNames.add(queue.DeveloperName);
        }

        return JSON.serialize(queueNames);
    }

    public Integer getLanguagesToMigrateCount()
    {
         return (languagesToMigrateCount == null ? 0 : languagesToMigrateCount);
    }

    public Integer getNewCustomFieldsCount()
    {
         return (newCustomFieldsCount == null ? 0 : newCustomFieldsCount);
    }

    public Integer getNewGroupsCount()
    {
         return (newGroupsCount == null ? 0 : newGroupsCount);
    }

    public Integer getNewTopicsAndBrandsCount()
    {
         return (newTopicsAndBrandsCount == null ? 0 : newTopicsAndBrandsCount);
    }

    public String getIsSandbox(){
        Organization currOrg = [Select IsSandbox from Organization limit 1];
        if(currOrg.IsSandbox) return 'true';
        else return 'false';
    }

    public String errorLevel { get; set; }
    public String messageName { get; set; }
    public String messageDetail { get; set; }
    public void showMessage()
    {        
        // determine the severity
        ApexPages.Severity severity = null;
        if (errorLevel == 'FATAL')
        {
            severity = ApexPages.Severity.FATAL;
        }
        else if (errorLevel == 'ERROR')
        {
            severity = ApexPages.Severity.ERROR;
        }
        else if (errorLevel == 'WARNING')
        {
            severity = ApexPages.Severity.WARNING;
        }
        else if (errorLevel == 'INFO')
        {
            severity = ApexPages.Severity.INFO;
        }
        else if (errorLevel == 'CONFIRM')
        {
            severity = ApexPages.Severity.CONFIRM;
        }

        ApexPages.addMessage(new ApexPages.Message(severity, messageName, messageDetail));
    }

    public PageReference moveStartMonthBackward(){
        Date limitDate = startWeekWrapperGrid[0].dateList[0].currentDate;
        //system.debug('*****limitDate ' + limitDate);
        if(limitDate < minDate){
            return null;
        }
        //system.debug('****currentStartMonth before changing ' + currentStartMonth);
        if(currentStartMonth == 0){
            currentStartMonth = 11;
            currentStartYear--;
        } else{
            currentStartMonth--;
        }
        //system.debug('****currentStartMonth ' + currentStartMonth + ' currentStartYear ' + currentStartYear);
        Date newStartMonthDate = date.newInstance(currentStartYear,currentStartMonth,1);
        this.startWeekWrapperGrid = initializeDatePickerGrid(newStartMonthDate);          
        return null;
    

    }

    public PageReference moveStartMonthForward(){
        //system.debug('****currentStartMonth before changing ' + currentStartMonth);
        if(currentStartMonth == 11){
            if(currentStartMonth < maxYear){
                currentStartMonth = 0;
                currentStartYear++;
            }
        } else{
            currentStartMonth++;
        }
        //system.debug('****currentStartMonth ' + currentStartMonth + ' currentStartYear ' + currentStartYear);
        Date newStartMonthDate = date.newInstance(currentStartYear,currentStartMonth,1);
        this.startWeekWrapperGrid = initializeDatePickerGrid(newStartMonthDate);        
        PageReference page = ApexPages.currentPage();

        return null;
    }

    public void clearMessages()
    {
        ApexPages.getMessages().clear();
    }

    public void refreshJSON()
    {
        getMigrationCustomFields();
        getMigrationGroups();
        newCustomFieldsJSON = newCustomFieldsJSON;        
        
    }

    public List<PreFlightCheck> getPreFlightChecks()
    {
        List<PreFlightCheck> preflighChecks = new List<PreFlightCheck>();

        // get a list of all objects
        Map<String,Schema.SObjectType> metadata = Schema.getGlobalDescribe();

        //get knowledge article type


        // query for the user-level permissions
        User u = [SELECT UserPermissionsKnowledgeUser, UserPermissionsSupportUser FROM User WHERE Id =: UserInfo.getUserId()];
//        Profile p = [SELECT PermissionsCreateAuditFields,PermissionsUpdateWithInactiveOwner,PermissionsCustomizeApplication,Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
//      TODO: The above filed are not available in the SELECT
        Profile p = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        // new PreFlightCheck(String Name, Boolean Pass, Boolean Required)

        /**
         * TODO:
         * API Access? Bulk and Metadata API Access?
         * Upsert on User, Group Members, Accounts, Contacts, Cases
         * Insert on Case Comments, Email Messages, Live Chat (if enabled), Knowledge (if enabled)
         * Access to Desk.com fields from Package and created via migrating metadata
         */

        // Service Cloud
        preflighChecks.add(new PreFlightCheck('System Administrator',(p.Name == 'System Administrator' ? true:false), true));
        preflighChecks.add(new PreFlightCheck('Service Cloud User Permission', u.UserPermissionsSupportUser, true));

        // Set Audit Fields upon Record Creation
        // TODO: the isCreateable() is returning false for some reason...
        preflighChecks.add(new PreFlightCheck('\'Set Audit Fields upon Record Creation\' Enabled',
            (Schema.sObjectType.Case.fields.CreatedDate.isCreateable()), false));

        // Update Records with Inactive Owners
        // TODO: How can we check for this?

        // Live Agent Enabled
        preflighChecks.add(new PreFlightCheck('Live Agent Enabled', metadata.containsKey('LiveAgentSession'), false));

        // Knowledge Enabled
        //Boolean knowledgeEnabled =false;
        //try {
        //    //DescribeSObjectResult objType = KnowledgeArticleVersion.getSObjectType().getDescribe();
        //    knowledgeEnabled = true;
        //} catch(Exception e) {
        //    System.debug('Knowledge is not enabled');
        //}
        //preflighChecks.add(new PreFlightCheck('Knowledge Enabled', knowledgeEnabled, false));

        // Knowledge User
        preflighChecks.add(new PreFlightCheck('Knowledge User Permission', u.UserPermissionsKnowledgeUser, false));
      //  preflighChecks.add(new PreFlightCheck('\'Update Records with Inactive Owners\'', p.PermissionsUpdateWithInactiveOwner, true));
        //preflighChecks.add(new PreFlightCheck('Customize Application', p.PermissionsCustomizeApplication, true));
        

        return preflighChecks;
    }

    @RemoteAction
    global static Id createMigrationStatusRemote()
    {
        SCMT__Desk_Migration__c deskMigration = new SCMT__Desk_Migration__c();
        //deskMigration.StartDate__c = Datetime.now();
        
        if(Schema.sObjectType.SCMT__Desk_Migration__c.isCreateable() && Schema.sObjectType.SCMT__Desk_Migration__c.fields.Status__c.isCreateable())
        {
            deskMigration.Status__c = 'New';
            Database.SaveResult sr = Database.insert(deskMigration, true);
            if (!sr.isSuccess())
            {
                String errorMessages = '';
                for (Database.Error err : sr.getErrors())
                {
                    errorMessages += err.getStatusCode() + ': ' + err.getMessage() + ' [' + err.getFields() + ']';
                }

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    'The creation of the migration status object failed!', errorMessages));
            }
        }else
        {
            throw new SCMTException('The creation of the migration status object failed!');
        }
        return deskMigration.Id;
        
    }

    // exception class
    public class SCMTException extends Exception {}
    /*public static Id createMigrationStatus()
    {
        deskMigration = new Desk_Migration__c();
        //deskMigration.StartDate__c = Datetime.now();
        deskMigration.Status__c = 'New';
        Database.SaveResult sr = Database.insert(deskMigration, true);
        if (!sr.isSuccess())
        {
            String errorMessages = '';
            for (Database.Error err : sr.getErrors())
            {
                errorMessages += err.getStatusCode() + ': ' + err.getMessage() + ' [' + err.getFields() + ']';
            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'The creation of the migration status object failed!', errorMessages));
        }
        system.debug('******deskMigration.Id ' + deskMigration.Id);
        return deskMigration.Id;
        
    }*/

    private String nameToDevName(String name)
    {
        return nameToDevName(name, 255);
    }

    private String nameToDevName(String name, Integer maxLength)
    {
        //System.debug('nameToDevName() entered: ' + Name);
        // The name used as a unique identifier for API access.
        // The 'Developer Name' can contain only underscores and alphanumeric characters.
        // It must be unique, begin with a letter, not include spaces, not end with an underscore, and not contain two
        // consecutive underscores.
        String devName = name.replaceAll('[^a-zA-Z\\d]', '_').replaceAll('(_)\\1+', '_');

        //System.debug('Name after replaceAll(): ' + devName);

        // begin with a letter
        Pattern startsWithAlpha = Pattern.compile('^[^a-zA-Z].*$');
        Matcher startsWithAlphaMatch = startsWithAlpha.matcher(devName);
        if (startsWithAlphaMatch != null && startsWithAlphaMatch.matches())
        {
            devName = 'A' + devName;
        }

        // apply a max length
        if (devName.length() > maxLength)
        {
            devName = devName.substring(0, maxLength);
        }

        // not end with an underscore
        while (devName.endsWith('_'))
        {
            devName = devName.removeEnd('_');
        }

        //System.debug('Name after removeEnd(): ' + devName);

        System.debug('nameToDevName() [' + Name + '] => [' + devName + ']');

        // return the developer name
        return devName;
    }

    public List<DeskLanguage> migrationLanguages = null;
    public List<DeskLanguage> getMigrationLanguages()
    {
        // check if we have generated languages already
        if (migrationLanguages != null)
        {
             return migrationLanguages;
        }

        System.debug(jsonData);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
        Map<String, Object> languages = (Map<String, Object>) m.get('languages');
        System.debug('languages: ' + languages);

        migrationLanguages = new List<DeskLanguage>();

        for (String langId : languages.keySet())
        {
            migrationLanguages.add(new DeskLanguage(languages.get(langId)));
        }

        // build the list of languages that will be migrated
        Set<String> languagesToMigrateSet = new Set<String>();

        // loop through the desk languages
        for (DeskLanguage lang : migrationLanguages)
        {
            // check if it is enabled
            if (lang.Enabled)
            {
                // add it to the list
                languagesToMigrateSet.add(lang.Id);
            }
        }

        // JSON encode the languages and put into a member var
        languagesToMigrateJSON = JSON.serialize(languagesToMigrateSet);
        languagesToMigrateCount = languagesToMigrateSet.size();

        return migrationLanguages;
    }

    public List<DeskCustomField> migrationCustomFields = null;
    public List<DeskCustomField> getMigrationCustomFields()
    {
        // check if we have already generated the custom fields
        if (migrationCustomFields != null)
        {
            return migrationCustomFields;
        }

        if(String.isBlank(jsonData)){
            return null;
        }
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
        List<Object> custom_fields = (List<Object>) m.get('custom_fields');
        if(custom_fields.isEmpty()){
            return null;
        }
        System.debug('custom_fields: ' + custom_fields);

        // build a map of object to list of fields on that object
        Map<String, Set<String>> objectFields = new Map<String, Set<String>>();
        objectFields.put('company', Schema.SObjectType.Account.fields.getMap().keySet());
        objectFields.put('customer', Schema.SObjectType.Contact.fields.getMap().keySet());
        objectFields.put('ticket', Schema.SObjectType.Case.fields.getMap().keySet());

        // declare the return list of custom fields
        migrationCustomFields = new List<DeskCustomField>();

        // loop through the json fields
        for (Object cfObj : custom_fields)
        {
            // create a new desk custom field object
            migrationCustomFields.add(new DeskCustomField(cfObj, objectFields));
        }

        // build a list of the custom fields that do not exist
        List<DeskCustomField> newCustomFields = new List<DeskCustomField>();
        for (DeskCustomField cf : migrationCustomFields)
        {
            if (!cf.Exists)
            {
                newCustomFields.add(cf);
            }
        }

        // put the list of new custom fields into the local member as JSON
        newCustomFieldsJSON = JSON.serialize(newCustomFields);
        System.debug('***'+newCustomFieldsJSON);
        newCustomFieldsCount = newCustomFields.size();

        // return the list of custom fields
        return migrationCustomFields;
    }

    @RemoteAction
    global static customFieldsGroupsMetadata getCustomFieldsAndGroups(String jsonData){
        List<DeskCustomField> customFields = getMigrationCustomFieldsRemote(jsonData);
        List<List<String>> customGroups = getMigrationGroupsRemote(jsonData);        
        customFieldsGroupsMetadata combinedMetadata = new customFieldsGroupsMetadata(customFields,customGroups);        
        return combinedMetadata;
    }

    @RemoteAction
    global static String getDeskMigrationId(String s){
    
            Id deskMigrationId = createMigrationStatusRemote();            
            return String.valueOf(deskMigrationId);
    }

    
    global static List<DeskCustomField> getMigrationCustomFieldsRemote(String jsonData)
    {
        // check if we have already generated the custom fields
        
        /*if (migrationCustomFields != null)
        {
            return migrationCustomFields;
        }*/

        if(String.isBlank(jsonData)){
            return null;
        }
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
        List<Object> custom_fields = (List<Object>) m.get('custom_fields');
        if(custom_fields.isEmpty()){
            return null;
        }
        System.debug('custom_fields: ' + custom_fields);

        // build a map of object to list of fields on that object
        Map<String, Set<String>> objectFields = new Map<String, Set<String>>();
        objectFields.put('company', Schema.SObjectType.Account.fields.getMap().keySet());
        objectFields.put('customer', Schema.SObjectType.Contact.fields.getMap().keySet());
        objectFields.put('ticket', Schema.SObjectType.Case.fields.getMap().keySet());

        // declare the return list of custom fields
        List<DeskCustomField> migrationCustomFields = new List<DeskCustomField>();

        // loop through the json fields
        for (Object cfObj : custom_fields)
        {
            // create a new desk custom field object
            migrationCustomFields.add(new DeskCustomField(cfObj, objectFields));
        }

        // build a list of the custom fields that do not exist
        List<DeskCustomField> newCustomFields = new List<DeskCustomField>();
        for (DeskCustomField cf : migrationCustomFields)
        {
            if (!cf.Exists)
            {
                newCustomFields.add(cf);
            }
        }

        return newCustomFields;
        // put the list of new custom fields into the local member as JSON
        //String newCustomFieldsJSON = JSON.serialize(newCustomFields);
        //System.debug('***newCustomFieldsJSON'+newCustomFieldsJSON);
        //newCustomFieldsCount = newCustomFields.size();

        // return the list of custom fields
        //newCustomFieldsJSON = 'testCustomFieldsJSOn';
        //return newCustomFieldsJSON;
    }

    global static List<List<String>> getMigrationGroupsRemote(String jsonData)
    {
        if(String.isBlank(jsonData)){
            return null;
        }
        // deserialize the JSON data into a map
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);

        // get the groups from the JSON map
        List<Object> groups = (List<Object>) m.get('groups');
        System.debug('groups: ' + groups);

        // get the list of queues
        List<Group> queues = [SELECT DeveloperName FROM Group WHERE Type = 'Queue'];

        // loop through the queues and build a set of queue names
        Set<String> queueNames = new Set<String>();
        for (Group queue : queues)
        {
            queueNames.add(queue.DeveloperName);
        }

        List<List<String>> migrationGroups = new List<List<String>>();

        // define a variable that will hold the list of new (does not exist) groups
        List<List<String>> newGroups = new List<List<String>>();

        for (Object groupObj : groups)
        {
            System.debug('Group Id: ' + groupObj);
            String devName = 'Desk_' + groupObj;

            // build the string list for the group
            List<String> groupStringList = new List<String> { String.valueOf(groupObj),
                (queueNames.contains(devName) ? 'true' : 'false') };

            // add the group to print
            migrationGroups.add(groupStringList);

            // check if the group exists
            if (!queueNames.contains(devName))
            {
                System.debug('New Group Name: ' + devName);
                // it does not exist, add it to be created
                newGroups.add(groupStringList);
            }
        }

        return newGroups;
    }

    public String getUserEmailAddress(){
        return UserInfo.getUserEmail();
    }
    public List<List<String>> getMigrationGroups()
    {
        // check if we have already build the migration groups
        if (migrationGroups != null)
        {
            return migrationGroups;
        }

         if(String.isBlank(jsonData)){
            return null;
        }
        // deserialize the JSON data into a map
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);

        // get the groups from the JSON map
        List<Object> groups = (List<Object>) m.get('groups');
        System.debug('groups: ' + groups);

        // get the list of queues
        List<Group> queues = [SELECT DeveloperName FROM Group WHERE Type = 'Queue'];

        // loop through the queues and build a set of queue names
        Set<String> queueNames = new Set<String>();
        for (Group queue : queues)
        {
            queueNames.add(queue.DeveloperName);
        }

        migrationGroups = new List<List<String>>();

        // define a variable that will hold the list of new (does not exist) groups
        List<List<String>> newGroups = new List<List<String>>();

        for (Object groupObj : groups)
        {
            System.debug('Group Id: ' + groupObj);
            String devName = 'Desk_' + groupObj;

            // build the string list for the group
            List<String> groupStringList = new List<String> { String.valueOf(groupObj),
                (queueNames.contains(devName) ? 'true' : 'false') };

            // add the group to print
            migrationGroups.add(groupStringList);

            // check if the group exists
            if (!queueNames.contains(devName))
            {
                System.debug('New Group Name: ' + devName);
                // it does not exist, add it to be created
                newGroups.add(groupStringList);
            }
        }

        // put the list of new custom fields into the local member as JSON
        newGroupsJSON = JSON.serialize(newGroups);
        newGroupsCount = newGroups.size();

        System.debug('Migration Groups: ' + migrationGroups);
        System.debug('New Groups: ' + newGroups);
        return migrationGroups;
    }

    List<selectOption> targetProfiles = null;
    List<selectOption> accountRecordTypes = null;
    List<selectOption> contactRecordTypes = null;
    List<selectOption> caseRecordTypes = null;

    public List<selectOption> getTargetProfiles()
    {
        // check if we have already build the migration groups
        if (targetProfiles != null)
        {
            return targetProfiles;
        }
        targetProfiles = new List<selectOption>();
        // get the list of Salesforce profiles
        for(Profile p:[SELECT Id,Name FROM Profile where UserLicense.Name like 'Salesforce' order by Name]){
            targetProfiles.add(new selectOption(p.Id,p.Name));
        }
        if(targetProfiles.size() > 0)
            return targetProfiles;
        else{
            targetProfiles.add(new selectOption('None', 'None'));
            return targetProfiles;   
        }
    }

    public List<selectOption> getAccountRecordTypes()
    {
        // check if we have already build the migration groups
        if (accountRecordTypes != null)
        {
            return accountRecordTypes;
        }
        accountRecordTypes = new List<selectOption>();
        // get all the account record types
        Schema.DescribeSObjectResult r = Account.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        for(Schema.RecordTypeInfo rec:RT){
            accountRecordTypes.add(new selectOption(rec.getRecordTypeId(),rec.getName()));
        }
        if(accountRecordTypes.size() > 0)
            return accountRecordTypes;
        else{
            accountRecordTypes.add(new selectOption('None', 'None'));
            return accountRecordTypes;   
        }
    }

    public List<selectOption> getContactRecordTypes()
    {
        // check if we have already build the migration groups
        if (contactRecordTypes != null)
        {
            return contactRecordTypes;
        }
        contactRecordTypes = new List<selectOption>();
        // get all the account record types
        Schema.DescribeSObjectResult r = Contact.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        for(Schema.RecordTypeInfo rec:RT){
            contactRecordTypes.add(new selectOption(rec.getRecordTypeId(),rec.getName()));
        }
        if(contactRecordTypes.size() > 0)
            return contactRecordTypes;
        else{
            contactRecordTypes.add(new selectOption('None', 'None'));
            return contactRecordTypes;   
        }
    }

    public List<selectOption> getCaseRecordTypes()
    {
        // check if we have already build the migration groups
        if (caseRecordTypes != null)
        {
            return caseRecordTypes;
        }
        caseRecordTypes = new List<selectOption>();
        // get all the account record types
        Schema.DescribeSObjectResult r = Case.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        for(Schema.RecordTypeInfo rec:RT){
            caseRecordTypes.add(new selectOption(rec.getRecordTypeId(),rec.getName()));
        }
        if(caseRecordTypes.size() > 0)
            return caseRecordTypes;
        else{
            caseRecordTypes.add(new selectOption('None', 'None'));
            return caseRecordTypes;   
        }
    }

    

    private List<List<String>> migrationTopicsAndBrands = null;
    public List<List<String>> getMigrationTopicsAndBrands()
    {
        // check if we have already build the migration topics
        if (migrationTopicsAndBrands != null)
        {
            return migrationTopicsAndBrands;
        }

        // deserialize the JSON data into a map
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);

        //// get the list of existing
        //List<Group> existing = [SELECT DeveloperName FROM Group WHERE Type = 'Queue'];

        //// loop through the records and build a set of existing names
        //Set<String> existingNames = new Set<String>();
        //for (Group queue : existing)
        //{
        //    existingNames.add(queue.DeveloperName);
        //}

        // initialize the list
        migrationTopicsAndBrands = new List<List<String>>();

        for (String topicOrBrand : new String[] { 'topics', 'brands' })
        {
            // get the topics from the JSON map
            List<Object> listObjs = (List<Object>) m.get(topicOrBrand);
            System.debug(topicOrBrand + ': ' + listObjs);

            for (Object listObj : listObjs)
            {
                migrationTopicsAndBrands.add(new List<String> { topicOrBrand, String.valueOf(listObj), nameToDevName(String.valueOf(listObj)),
                    'false'/*(existingNames.contains(String.valueOf(listObj)) ? 'true' : 'false')*/ } );
            }
        }

        this.newTopicsAndBrandsJSON = JSON.serialize(migrationTopicsAndBrands);
        this.newTopicsAndBrandsCount = 0;

        System.debug('Migration Topics & Brands: ' + migrationTopicsAndBrands);
        return migrationTopicsAndBrands;
    }

    public class DeskLanguage
    {
        public String Id { get; private set; }
        public String Name { get; private set; }
        public String SalesforceCode { get; private set; }
        public Boolean Supported { get; private set; }
        public Boolean Enabled { get; private set; }

        public DeskLanguage(Object langObj)
        {
            Map<String, Object> langMap = (Map<String, Object>) langObj;

            this.Id = String.valueOf(langMap.get('id'));
            this.Name = String.valueOf(langMap.get('name'));
            this.SalesforceCode = String.valueOf(langMap.get('salesforce_code'));
            this.Supported = Boolean.valueOf(langMap.get('supported'));
            this.setEnabledLocal();
        }

        public DeskLanguage(String Id, String Name, String SalesforceCode, Boolean Supported)
        {
            this.Id = Id;
            this.SalesforceCode = SalesforceCode;
            this.Name = Name;
            this.Supported = Supported;
            this.setEnabledLocal();
        }

        private void setEnabledLocal()
        {
            this.Enabled = false;

            //System.debug('Salesforce Code: ' + this.SalesforceCode);
            // pull the language picklist from the 'User.LanguageLocaleKey' field
            List<Schema.PicklistEntry> langs = User.LanguageLocaleKey.getDescribe().getPicklistValues();

            // loop through the values
            for (Schema.PicklistEntry lang : langs)
            {
                //System.debug(lang);
                // check if the salesforce code matches the value
                if (this.SalesforceCode == lang.getValue())
                {
                    //System.debug('Found ' + this.SalesforceCode);
                    // set the language as an enabled language and break out of the for loop
                    this.Enabled = true;
                    break;
                }
            }
        }
    }

    global class customFieldsGroupsMetadata
    {
        public List<DeskCustomField> deskFields {get; set;}
        public List<List<String>> groups {get; set;}
        
        public customFieldsGroupsMetadata(List<DeskCustomField> deskFields,List<List<String>> groups){
            this.deskFields = deskFields;
            this.groups = groups;
        }

    }

    global class DeskCustomField
    {
        public String Name { get; private set; }
        public String DeveloperName { get; private set; }
        public String Label { get; private set; }
        public String Parent { get; private set; }
        public Boolean Active { get; private set; }
        public String Type { get; private set; }
        public String Other { get; private set; }
        public Boolean Exists { get; private set; }

        public DeskCustomField(Object cfObj, Map<String, Set<String>> objectFields)
        {
            Map<String, Object> cfMap = (Map<String, Object>) cfObj;
            Map<String, Object> dataMap = (Map<String, Object>) cfMap.get('data');
            String other = '';

            // check if there are choices to list
            if (dataMap.containsKey('choices'))
            {
                List<Object> choicesObj = (List<Object>) dataMap.get('choices');
                for (Object choiceObj : choicesObj)
                {
                    other += String.valueOf(choiceObj) + ', ';
                }
                other = other.removeEnd(', ');
            }

            // assign values to local member variables
            this.Name = String.valueOf(cfMap.get('name'));
            this.DeveloperName = 'Desk_' + this.Name + '__c';
            this.Label = String.valueOf(cfMap.get('label'));
            this.Parent = String.valueOf(cfMap.get('type'));
            this.Active = Boolean.valueOf(cfMap.get('active'));
            this.Type = String.valueOf(dataMap.get('type'));
            this.Other = other;

            //System.debug('Object: [' + this.Parent + ']');
            //System.debug('DeveloperName: [' + this.DeveloperName.toLowerCase() + ']');
            //System.debug('Exists: [' + objectFields.get(this.Parent).contains(this.DeveloperName.toLowerCase()) + ']');

            this.Exists = (objectFields.get(this.Parent).contains(this.DeveloperName.toLowerCase()));
        }

        public DeskCustomField(String Name, String Label, String Parent, Boolean Active, String Type, String Other, Boolean Exists)
        {
            this.Name = Name;
            this.Label = Label;
            this.Parent = Parent;
            this.Active= Active;
            this.Type = Type;
            this.Other = Other;
        }
    }

    public class WeekWrapper{
        public list<DateWrapper> dateList {get; set;}
        public integer weekIndex {get; set;}
         
        public WeekWrapper(Integer weekIndex,Date weekStartDate,Date currentReferenceDate){
            weekIndex = weekIndex;
            system.debug('***in ww and weekStartDate is ' + weekStartDate);
            Date datePlaceholder = weekStartDate;
            dateList = new list<DateWrapper>();
            for(integer i=0;i<7;i++){
                DateWrapper dw = new DateWrapper(datePlaceholder,currentReferenceDate);
                datePlaceHolder = datePlaceholder + 1;
                dateList.add(dw);
            }
            system.debug('****dateList ' + dateList);
        } 
    }


    public class DateWrapper{
        public date currentDate {get;set;}
        public boolean enabled {get; set;}
        public boolean selected {get; set;}
        public String currentDay {get; set;}
        public integer currentDateComponent {get; set;}
        public integer currentMonthComponent {get; set;}
        public integer currentYearComponent {get; set;}
        
        public DateWrapper(Date d,Date currentReferenceDate){
            currentDate = d;
            currentDateComponent = currentDate.day();
            currentMonthComponent = currentDate.month();
            currentYearComponent = currentDate.year();
            system.debug('***currentDate ' + currentDate + ' ' + currentReferenceDate); 
            enabled = (d.month() == currentReferenceDate.month() ? true : false);
            selected = (d == date.today() ? true : false); 
            Datetime currentDateTime = datetime.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
            currentDay = currentDateTime.format('EEE');
        } 
    }

    public class PreFlightCheck
    {
        public String Name { get; private set; }
        public Boolean Pass { get; private set; }
        public Boolean Required { get; private set; }
        public String CssClass { get; private set; }
        public String Icon { get; private set; }

        public PreFlightCheck(String Name, Boolean Pass, Boolean Required)
        {
            this.Name = Name;
            this.Pass = Pass;
            this.Required = Required;

            if (this.Pass)
            {
                this.Icon = 'check';
                this.CssClass = 'slds-icon-text-default slds-icon-text-good';
            }
            else
            {
                if (this.Required)
                {
                    this.Icon = 'ban';
                    this.CssClass = 'slds-icon-text-error';
                }
                else
                {
                    this.Icon = 'warning';
                    this.CssClass = 'slds-icon-text-warning';
                }
            }
            this.CssClass += ' icon-utility-' + this.Icon;
        }
    }


}