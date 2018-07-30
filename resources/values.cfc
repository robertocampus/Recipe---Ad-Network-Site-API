<!--- 
	
	Comments from Roberto - I think we need to have some security in place. The current code will allow any table contents.
	
	1) We need to limit to tables that start with "val_" only. 
	
	How do we secture this method and others to be only available from the same origin? I.e. only from GET requests coming from the same URL as the server 
	hosting this API. Is this an API wide settings/config that Taffy provides?
	
--->

<cfcomponent extends="taffyAPI.base" taffy:uri="/values/{table_name}" hint="Used to retrieve all records of a master table.">

	<cffunction name="GET" access="public" returntype="struct" output="false" hint="To get a master table records.">
		<cfargument name="table_name" type="string" required="true" hint="A master table name.">

		<cfset var result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = "" />
		<cfset local.query = "" />

		<cftry>
			<cfif listFirst( arguments.table_name, '_' ) EQ 'val' >
				
				<!--- // comment from roberto: the columnStruct looks great, but we need to make the table column names come from the
					      database itself, not being hardcoded.  Some code that might be useful can be found in the file /socialfoodie.co/com/db.cfc line 1504 
					  // --->
				
				<cfscript>
					columnStruct = {
								"val_action"				: ["actionID","actionName","actionDescription"],
								"val_adlocations"			: ["adLocationID","adLocationName",""],
								"val_adunittype"			: ["adUnitTypeID","adUnitName",""],
								"val_buyers"				: ["buyerID","buyerName","buyerDescription"],
								"val_category"				: ["categoryID","categoryName","categoryDescription"],
								"val_commentstatus"			: ["commentStatusID","commentStatusName","commentStatusDescription"],
								"val_commenttype" 			: ["commentTypeID","commentTypeName","commentTypeDescription"],
								"val_contestactivitytype" 	: ["contestActivityTypeID","contestActivityTypeName","contestActivityTypeDescription"],
								"val_contestdeclinereason" 	: ["contestdeclinereasonID","contestdeclinereasonName","contestdeclinereasonDescription"],
								"val_contestregion" 		: ["contestRegionID","contestRegionName","contestRegionDescription"],
								"val_contesttype" 			: ["contestTypeID","contestTypeName","contestTypeDescription"],
								"val_contestwinnerstatus" 	: ["contestWinnerStatusID","contestWinnerStatusName","contestWinnerStatusDescription"],
								"val_countries"				: ["countryID","countryFullName",""],
								"val_demographics_age"		: ["ageID","ageName","ageDescription"],
								"val_demographics_children"	: ["childrenID","childrenName","childrenDescription"],
								"val_demographics_education": ["educationID","educationName","educationDescription"],
								"val_demographics_ethnicity": ["ethnicityID","ethnicityName","ethnicityDescription"],
								"val_demographics_income"	: ["incomeID","incomeName","incomeDescription"],
								"val_emailtype" 			: ["emailTypeID","emailTypeName","emailTypeDescription"],
								"val_entitytype" 			: ["entityTypeID","entityTypeName","entityTypeDescription"],
								"val_featuredtype"			: ["ID","name","description"],
								"val_friendstatus" 			: ["friendStatusID","friendStatusName","friendStatusDescription"],
								"val_grouptype" 			: ["groupTypeID","groupTypeName","groupTypeDescription"],
								"val_httpstatuscode" 		: ["ID","Name","Description"],
								"val_imagetype" 			: ["imageTypeID","imageTypeName","imageTypeDescription"],
								"val_issuetype" 			: ["issueTypeID","issueTypeName","issueTypeDescription"],
								"val_itemtype"				: ["itemTypeID","itemTypeName","itemTypeDescription"],
								"val_influencer_options"	: ["optionID","optionName","optionDescription"],
								"val_language" 				: ["languageID","languageName",""],
								"val_leadentitytype" 		: ["leadEntityTypeID","leadEntityTypeName",""],
								"val_leadinterested" 		: ["leadInterestedID","leadInterestedName",""],
								"val_leadsource" 			: ["leadSourceID","leadSourceName",""],
								"val_leadstage"				: ["leadStageID","leadStageName",""],
								"val_leadstatus" 			: ["leadStatusID","leadStatusName",""],
								"val_leadtimeframe" 		: ["leadTimeFrameID","leadTimeFrameName",""],
								"val_leadtype" 				: ["leadTypeID","leadTypeName",""],
								"val_location"				: ["locationID","locationName","locationDescription"],
								"val_messagetype" 			: ["messageTypeID","messageTypeName",""],
								"val_monthpayments" 		: ["id","",""],
								"val_openx_oauth"			: ["oauth_ID","",""],
								"val_orders" 				: ["order_ID","line_item_name",""],
								"val_preferencetype"		: ["preferenceTypeID","preferenceTypeName","preferenceTypeDescription"],
								"val_priority" 				: ["priorityID","priorityName",""],
							 	"val_programs" 				: ["programID","programName","programDescription"],
								"val_programsitestatus" 	: ["programSiteStatusID","programSiteStatusName","programSiteStatusDescription"],
								"val_publisheraccounttype" 	: ["publisherAccountTypeID","publisherAccountTypeName","publisherAccountTypeDescription"],
								"val_publisheradtag" 		: ["publisherAdTagID","publisherAdTagName","publisherAdTagDescription"],
								"val_publishercompanytype" 	: ["publisherCompanyTypeID","publisherCompanyTypeName","publisherCompanyTypeDescription"],
								"val_publisherrejectreason" : ["ID","Name","Description"],
								"val_publisherstatus" 		: ["publisherStatusID","publisherStatusName","publisherStatusDescription"],
								"val_questiontype" 			: ["questionTypeID","questionTypeName","questionTypeDescription"],
								"val_recipe_allergy" 		: ["allergyID","allergyName","allergyDescription"],
								"val_recipe_amounttype" 	: ["amountTypeID","amountTypeName","amountTypeDescription"],
								"val_recipe_channel"		: ["channelID","channelName","channelDescription"],
								"val_recipe_course" 		: ["courseID","courseName","courseDescription"],
								"val_recipe_cuisine" 		: ["cuisineID","cuisineName","cuisineDescription"],
								"val_recipe_diet" 			: ["dietID","dietName","dietDescription"],
								"val_recipe_difficulty"     : ["difficultyID","difficultyName","difficultyDescription"],
								"val_recipe_holiday" 		: ["holidayID","holidayName","holidayDescription"],
								"val_recipe_importdatatype" : ["ID","Name","Description"],
								"val_recipe_ingredient" 	: ["ingredientID","ingredientName",""],
								"val_recipe_occasion" 		: ["occasionID","occasionName","occasionDescription"],
								"val_recipe_season" 		: ["seasonID","seasonName","seasonDescription"],
								"val_recipe_unittype" 		: ["unitTypeID","unitTypeName","unitTypeDescription"],
								"val_rejectedreason" 		: ["ID","Name","Description"],
								"val_report_columns" 		: ["col_id","col_name",""],
								"val_reportlogtype" 		: ["reportLogTypeID","reportLogTypeName","reportLogTypeDescription"],
								"val_role" 					: ["roleID","roleName","roleDescription"],
								"val_siterejectedreason" 	: ["ID","name","description"],
								"val_sitesuspendedreason" 	: ["ID","name","description"],
								"val_socialtype" 			: ["socialTypeID","socialTypeName","socialTypeDescription"],
								"val_source" 				: ["sourceID","sourceName","sourceDescription"],
								"val_sponsorcategory" 		: ["sponsorCategoryID","sponsorCategoryName","sponsorCategoryDescription"],
								"val_sponsorindustry" 		: ["sponsorIndustryID","sponsorIndustryName","sponsorIndustryDescription"],
								"val_states" 				: ["stateID","stateName",""],
								"val_status" 				: ["statusID","statusName","statusDescription"],
								"val_statuschecktype" 		: ["statusCheckTypeID","StatusCheckName","StatusCheckDescription"],
								"val_subtype" 				: ["subtypeID","subtypeName","subtypeDescription"],
								"val_supportsubtype"		: ["supportSubTypeID","supportSubTypeName","supportSubTypeDescription"],
								"val_supporttype" 			: ["supportTypeID","supportTypeName","supportTypeDescription"],
								"val_talrejectedreason" 	: ["ID","Name","Description"],
								"val_thumbnailstatus" 		: ["thumbnailStatusID","thumbnailStatusName","thumbnailStatusDescription"],
								"val_ticketstatus" 			: ["ticketStatusID","ticketStatusName","ticketStatusDescription"],
								"val_timezone" 				: ["timeZoneID","timeZoneName","timeZoneDescription"],
								"val_type" 					: ["typeID","typeName","typeDescription"],
								"val_widgetstatus" 			: ["widgetStatusID","widgetStatusName","widgetStatusDescription"]
								}
				</cfscript>				

				<cfquery datasource="#variables.datasource#" name="result.query">				
					SELECT 
						#columnStruct[arguments.table_name][1]# as id
						<cfif len(trim(#columnStruct[arguments.table_name][2]#))>
						,#columnStruct[arguments.table_name][2]# as name
						</cfif>
						<cfif len(trim(#columnStruct[arguments.table_name][3]#))>
						,#columnStruct[arguments.table_name][3]# as description
						</cfif>
					 FROM #lCase(trim(arguments.table_name))#
					WHERE active = <cfqueryparam value="1" cfsqltype="cf_sql_integer"> 
				</cfquery>

				<cfif NOT result.query.recordcount >
					<cfset result.message = application.messages['values_get_found_error']>
					<cfreturn representationOf(result).withStatus(404)>
				</cfif>

			<cfelse>
				<cfset result.message = application.messages['values_get_found_error']>
				<cfreturn representationOf(result).withStatus(404)>
			</cfif>

			<cfcatch>


				<cfset local.logAction = logAction( actionID = 9, extra = "method: /values/GET", errorCatch = variables.cfcatch )>

				<cfset local.message = errorMessage(message='database_query_error', error = variables.cfcatch)>

				<cfreturn representationOf(local.message).withStatus(500)>

			</cfcatch>

		</cftry>


		<cfset local.logAction = logAction(actionID = 8, extra = "method: /values/GET" )>

		<cfset result.value_table = "#lcase(arguments.table_name)#">		
		<cfset result.status = true>
		<cfset result.message = application.messages['values_get_found_success']>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>
	
</cfcomponent>