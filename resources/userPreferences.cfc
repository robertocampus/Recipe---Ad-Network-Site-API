<cfcomponent extends="taffyAPI.base" taffy:uri="/userPreferences/" hint="used to insert or update the users  preferences.">

	<cffunction name="GET" access="public" hint="Return User Preferences DATA" returntype="struct" output="false">
		<cfargument name="UserID" 			type="string" required="yes" hint="User ID">
		<cfargument name="preferenceTypeID" type="string" required="no"  hint="Preference Type ID">
		<cfargument name="pagination"		type="struct" required="no"  default="#StructNew()#" >

 		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
 		<cfset result['message']    = ''>
		<cfparam name="arguments.pagination.orderCol" default="P.UserID"/>

		<cftry>
		
			<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
				arguments.pagination = checkPagination(arguments.pagination);

			</cfscript>

	  		<cfquery datasource="#variables.datasource#" name="result.query">

				SELECT   
	            	P.preferenceID,
	  				P.preferenceTypeID,
	  				P.preferenceValue,
					V.preferenceTypeName,
					V.preferenceTypeDescription 

				FROM preferences P
				LEFT JOIN val_preferencetype V on V.preferenceTypeID = P.preferenceTypeID
	 			WHERE P.UserID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.UserID#">

				<cfif structKeyExists(arguments,"preferenceTypeID") AND arguments.preferenceTypeID NEQ "">
			  		AND P.preferenceTypeID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.preferenceTypeID#" list="yes"> )
			  	</cfif>

			  	ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# LIMIT #arguments.pagination.offset#, #arguments.pagination.limit# 
			  	
			</cfquery>
			
			<cfset result.status = true />

				 
			<cfcatch>

				<!--- :: degrade gracefully :: --->
				
				<cfset result.message = errorMessage(message = 'userPreferences_get_found_error', error = variables.cfcatch)>

				<!--- // 666, 'Database Error', 1 --->
				<cfset logAction( actionID = 666, extra = "method: /userPreferences/GET", errorCatch = variables.cfcatch  )>	
				
			  	<cfreturn representationOf(result.message).withStatus(500)>

	        </cfcatch>
			
	    </cftry>

	    <cfset result.message = application.messages['userPreferences_get_found_success']>
		<cfset logAction( actionID = 8100, extra = "method: /userPreferences/GET")>
 		<cfreturn  representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="PUT" access="public" output="false" returntype="struct" hint="Update the preferences">

		<cfargument name="preferences"	type="string" 	required="yes" 	hint="List of Preferences ID.">
		<cfargument name="userID"		type="numeric" 	required="yes"  hint="userID">
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message']	= ''>
		
		<cftry>
		
			<!--- // reset all preferences to 0 --->
			<cfquery datasource="#variables.datasource#" name="local.query">

			    UPDATE preferences
			      SET preferenceValue = <cfqueryparam value="0" cfsqltype="cf_sql_integer">   
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">

			</cfquery>	
		
			<!--- // activate slected preferences --->
			<cfquery datasource="#variables.datasource#" name="local.query">

			    UPDATE preferences
			      SET preferenceValue = <cfqueryparam value="1" cfsqltype="cf_sql_integer">   
				WHERE preferenceID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.preferences#" list="yes"> )  
				  AND userID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">

			</cfquery>
			
			<cfset result.status = true />
			
		<!--- // 8102, 'Preferences: Updated', 'User updated preferences successfully.', 1 --->
			<cfset logAction( actionID = 8102,  extra = "method: /userPreferences/PUT" )>	
				
			<cfcatch>

				<cfset result.message = errorMessage( message = 'userPreferences_put_update_error', error = variables.cfcatch)>
			<!--- // 8103, 'Error : Preferences', 'Error encountered while updating or processing preferences update.', 1 --->
				<cfset logAction( actionID = 8103, errorCatch = variables.cfcatch,extra = "method: /userPreferences/GET"  )>	
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch> 

		</cftry>

		<cfset result.message = application.messages['userPreferences_put_update_success'] />

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	


	<!--- :: METHOD: insertPreferences :: --->
	<cffunction name="POST" access="public" hint="Insert Preferences" returntype="struct" output="false">
		<cfargument name="userID"	type="string" 	required="yes"  hint="User ID">
		
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew()>
	
		<cfset result['status']  	= false>
		<cfset result['message']	= ''>

		<cftry>

			<!--- // reset all preferences to 0 --->
			<cfset local.query="">
			<cfquery datasource="#variables.datasource#" name="local.query" result="query">

		        INSERT INTO preferences ( preferenceTypeID, preferenceValue, userID )
					SELECT  preferenceTypeID,
					preferenceTypeDefault,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
					FROM val_preferencetype

			</cfquery>	

	  		<cfset result.status = true>
			
			<!--- // 8104, 'Preferences: Inserted', 'User preferences inserted successfully.', 1 --->
		    <cfset logAction( actionID = 8104, extra = "method: /userPreferences/POST")>	
			
			<cfcatch>
				<cfset result.message = errorMessage(message = 'userPreferences_post_add_error')>
				<!--- // 8105, 'Error : Prefereces: Insert Error', 'Error encountered while inserting user preferences.', 1 --->
				<cfset logAction( actionID = 8105,extra = "method: /userPreferences/POST", errorCatch = variables.cfcatch)>
				<cfreturn representationOf(result.messages).withStatus(500)>

			</cfcatch> 

		</cftry>

		<cfset result.message = application.messages['userPreferences_post_add_success']>
		
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


</cfcomponent>