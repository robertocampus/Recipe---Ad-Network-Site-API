<cfcomponent displayname="FBR DAO" hint="General Data Access Object" output="true" extends="taffy.core.resource" >

	<!--- :: METHOD: init :: --->
	<cffunction name="init" access="public" hint="Initialize DAO Object">
		<cfargument name="dataSource" type="string" required="yes" hint="DNS name">

		<cfset variables.dataSource = arguments.dataSource />

		<cfreturn this />
	</cffunction>

	<cfset variables.dataSource           = application.dataSource />
	<cfset variables.url 			      = application.appBaseURL >
	<cfset variables.title 			      = application.title >
	<cfset variables.emailUsername        = application.emailUsername >
	<cfset variables.emailPassword        = application.emailPassword >
	<cfset variables.emailServer 	      = application.emailServer >
	<cfset variables.emailServerPortSMTP  = application.emailServerPortSMTP >
	<cfset variables.emailServerSSL       = application.emailServerSSL >
	<cfset variables.supportEmail         = application.supportEmail >
	<cfset variables.adminEmail			  = application.adminEmail >

	<!--- :: METHOD: checkPagination :: --->
	<cffunction name="checkPagination" access="public" hint="Check/Returns standard pagination struct">
		<cfargument name="pagination" type="struct" required="true" />

		<!--- :: init result structure --->
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />

		<cfscript>
			local.pagination = arguments.pagination;

			if ( !structKeyExists(pagination, "offset") ) {
				local.pagination.offset = 0;
			};

			if ( !structKeyExists(pagination, "limit") ) {
				local.pagination.limit = 50;
			};

			if ( !structKeyExists(pagination, "orderCol") ) {
				local.pagination.orderCol = "";
			}

			if ( !structKeyExists(pagination, "orderDir") ) {
				local.pagination.orderDir = "ASC";
			}

			result = local.pagination;
		</cfscript>

		<cfreturn result />
	</cffunction>


	<!--- :: METHOD: logActivity :: --->
	<cffunction name="logActivity" access="public" hint="Log Activity" returntype="struct" output="true">
		<cfargument name="userID" 		 type="string" required="yes"  				hint="USER VARS structure">
		<cfargument name="component"	 type="string" required="yes"				hint="name of component">
		<cfargument name="action" 		 type="string" required="yes" 				hint="Unique action name">
		<cfargument name="activityID" 	 type="string" required="no"  default="0"	hint="Unique action name">
		<cfargument name="activityType"  type="string" required="no"  default="0"	hint="Unique action name">
		<cfargument name="content" 		 type="string" required="yes" 				hint="Activity header Text to display">
		<cfargument name="excerpt" 		 type="string" required="no"  default=""	hint="Text of excerpt">
		<cfargument name="primary_link"  type="string" required="no"  default=""	hint="Primary link (if available)">
		<cfargument name="typeID" 	 	 type="string" required="no"  default="0"	hint="TypeID of primary object (if available)">
		<cfargument name="groupID" 	 	 type="string" required="no"  default="0"	hint="GroupID of primary object (if available)">
		<cfargument name="objectID" 	 type="string" required="no"  default="0"	hint="ID of primary object (if available)">
		<cfargument name="s_objectID" 	 type="string" required="no"  default="0"	hint="ID of secondary object (if available)">
		<cfargument name="isVisibleSitewide" type="string" required="no"  default="0"	hint="Hide activity (if available - default to 0)">

		<!--- :: init result structure --->
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />
		<cfset result.status  	= false />

		<!---<cftry>--->

	   	<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">

		<cfquery datasource="#variables.dataSource#" name="local.insertLOG">
		INSERT INTO activity
					(
						userID,
						component,
						action,
						activityID,
						activityType,
						content,
						excerpt,
						primary_link,
						typeID,
						groupID,
						objectID,
						s_objectID,
						createDate,
						isVisibleSitewide
					)
			VALUES 	(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_string"  value="#arguments.component#">,
						<cfqueryparam cfsqltype="cf_sql_string"  value="#arguments.action#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.activityID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.activityType#">,
						<cfqueryparam cfsqltype="cf_sql_string"  value="#arguments.content#">,
						<cfqueryparam cfsqltype="cf_sql_string"  value="#left(arguments.excerpt,255)#">,
						<cfqueryparam cfsqltype="cf_sql_string"  value="#left(arguments.primary_link,150)#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.typeID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.groupID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.objectID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.s_objectID#">,
						'#local.timeStamp#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isVisibleSitewide#">
					)
	    </cfquery>

			<cfset result.status = true />

	<!---   		    <cfcatch>

		      <!--- :: degrade gracefully :: --->
		      <cfset result.message = 999>
		      <!--- "There was a problem with the last operation. The system administrator has been notified." --->

			  <!--- ERROR : LOG DETAILS OF ERROR HERE --->

	        </cfcatch>

	      </cftry>--->


		<cfreturn result />
	</cffunction>


	<!--- :: METHOD: logAction :: --->
	<cffunction name="logAction" access="public" hint="Log Action" returntype="struct" output="true">
		<cfargument name="actionID"		type="string" required="yes"							hint="ID of action to be logged">
		<cfargument name="blogID"		type="string" required="no"  default="" 				hint="ID of blog (if available)">
		<cfargument name="itemID" 		type="string" required="no"  default="" 				hint="ID of Item (if available)">
		<cfargument name="CGI" 			type="struct" required="no"  default="#StructNew()#" 	hint="CGI VARS structure">
		<cfargument name="user" 		type="struct" required="no"  default="#StructNew()#" 	hint="USER VARS structure">
		<cfargument name="extra" 		type="string" required="no"  default=""					hint="Extra data">
		<cfargument name="errorCatch" 	required="no"  default="#StructNew()#"	hint="Extra Error catch structure">

		<!--- :: init result structure --->
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />
		<cfset result.status  	= false />

			<cftry>

		   	<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">

			    <cfquery datasource="#variables.dataSource#" name="local.insertLOG">
				INSERT INTO log (
									actionID,
									userID,
									blogID,
									logDate,
									ip,
									itemID,
									extra,
									active
								)
					VALUES 	( 	#val(arguments.actionID)#,
								'<cfif StructKeyExists(arguments.user, "userID")>#arguments.user.userID#<cfelse>1</cfif>',
								#val(arguments.blogID)#,
								'#local.timeStamp#',
								'<cfif StructKeyExists(arguments.CGI, "REMOTE_ADDR")>#arguments.CGI.REMOTE_ADDR#</cfif>',
								#val(itemID)#,
								<cfqueryparam cfsqltype="cf_sql_string" value="#arguments.extra#">,
								1
							)
	        </cfquery>

			<!--- // if ERROR, log it and tie it to this log entry --->
			<cfif StructCount(arguments.errorCatch) GT 0>

				<cfquery datasource="#variables.dataSource#" name="local.getLast">
					SELECT LAST_INSERT_ID() AS ID
				</cfquery>

				<cfquery datasource="#variables.dataSource#" name="local.insertError">
					INSERT INTO errors (
									<cfif StructKeyExists(arguments.errorCatch, "Type")>errorType,</cfif>
									<cfif StructKeyExists(arguments.errorCatch, "Message")>errorMessage,</cfif>
									<cfif StructKeyExists(arguments.errorCatch, "Detail")>errorDetail,</cfif>
									<cfif StructKeyExists(arguments.errorCatch, "SQL")>errorSQL,</cfif>
									logID,
									active )
					VALUES 	(
								 <cfif StructKeyExists(arguments.errorCatch, "Type")>'#arguments.errorCatch.Type#',</cfif>
								 <cfif StructKeyExists(arguments.errorCatch, "Message")>'#arguments.errorCatch.Message#',</cfif>
								 <cfif StructKeyExists(arguments.errorCatch, "Detail")>'#arguments.errorCatch.Detail#',</cfif>
								 <cfif StructKeyExists(arguments.errorCatch, "SQL")>'#arguments.errorCatch.SQL#',</cfif>
								 #val(local.getLast.ID)#,
								 1 )
				</cfquery>

			</cfif>


		    <cfset result.status = true />

			    <cfcatch>

		      <!--- :: degrade gracefully :: --->
		      <cfset result.message = 999>
		      <!--- "There was a problem with the last operation. The system administrator has been notified." --->

			  <!--- ERROR : LOG DETAILS OF ERROR HERE --->

	        </cfcatch>

	      </cftry>


		<cfreturn result />
	</cffunction>

	<!--- :: METHOD: queryToStruct :: --->
	<cffunction name="queryToStruct" access="public" hint="Converts query to struct (pass column)">
			<cfargument name="query" 	type="query" required="true" />
		<cfargument name="keyCol" 	type="string" required="true" />
		<cfargument name="valueCol"	type="string" required="true" />

			<!--- :: init result structure --->
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />

		<cfscript>
			local.startIndex = 1;
			local.endIndex = arguments.query.recordCount;

			// Loop over the rows to create a structure for each row.
			for (local.rowIndex = local.startIndex; local.rowIndex LTE local.endIndex ; local.rowIndex = (LOCAL.rowIndex + 1)){

				// Set column value into the structure.
				result[ "#arguments.Query[ "#arguments.keyCol#" ][ local.RowIndex ]#" ] = arguments.Query[ "#arguments.valueCol#" ][ local.RowIndex ];

			}
		</cfscript>

		<cfreturn result />
	</cffunction>


	<cffunction name="downloadAndUploadFile" access="private" returntype="void" output="false">
		<cfargument name="fileURL"  required="true" type="string">
		<cfargument name="filePath" required="true" type="string">
		<cfargument name="fileName" required="true" type="string">

		<cfhttp method="GET" url="#arguments.fileURL#" path="#arguments.filePath#" file="#arguments.fileName#">

	</cffunction>

	<!--- :: METHOD: toSlug :: --->
	<cffunction name="toSlug" access="public" hint="Create SEO friendly slug from string" returntype="string">
		<cfargument name="myString" type="string" required="yes" hint="String to convert to SLUG">

 		<!--- :: init result structure --->
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result.status  	= false />

		  <cfscript>
			// creates slug from string, also works with URLs
			local.myString = ReplaceNoCase( trim(arguments.myString), 'http://', '');
			local.myString = ListGetAt(local.myString, 1, '?');
			local.myString = ReplaceNoCase( local.myString, '.html', '');
			local.myString = ReplaceNoCase( local.myString, '.cfm', '');
			local.myString = ReplaceNoCase( local.myString, '.asp', '');
			local.myString = ReplaceNoCase( local.myString, 'index.php', '');

			local.myString = REReplace(local.myString, "[[:punct:]]", " ", "ALL");
		    local.myString = LCase(REReplace(local.myString, "[[:space:]]+", "-", "ALL"));

		    if ( right(local.myString,1) EQ "-" ) {
		     	local.myString = left(local.myString, (len(local.myString)-1));
		    }

		    if ( left(local.myString,1) EQ "-" ) {
		     	local.myString = right(local.myString, (len(local.myString)-1));
		    }

			result = local.myString;
	 	</cfscript>

	  <cfreturn result />
	</cffunction>

	<!--- :: METHOD: getWeekStartDate :: --->
	<cffunction name="getWeekStartDate" access="public" hint="Get Sunday Get" returntype="string" output="false">
    	<cfargument name="day" type="string" required="false"  default="1" hint="Day of week (1:sunday, 2:monday, etc)">

 		<!--- :: init result structure --->
 		<cfset var result 	= "" />
		<cfset var local  	= StructNew() />

		<cfscript>

			local.thisDate = "#DateFormat(now(), "YYYY-MM-DD")# 00:00:00";

	        for ( i=1; i <= 7; i=i+1 ) {

	             if ( dayOfWeek(local.thisDate) EQ arguments.day ) {
	                break;
	            }

	            local.thisDate = DateFormat(DateAdd("D", -1, local.thisDate), "YYYY-MM-DD");
	        }

			result = local.thisDate;

        </cfscript>

 		<cfreturn result />

	</cffunction>

	<!--- :: METHOD: checkUserBlogs :: --->
	<cffunction name="checkUserBlogs" access="public" hint="Return user blogs IDs" returntype="struct" output="false">
		<cfargument name="userID" type="string" required="yes" hint="User ID">
		<cfargument name="blogID" type="string" required="no" hint="Blog ID">

		<!--- :: init result structure --->
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />

		<cftry>

			<cfquery datasource="#variables.datasource#" name="local.query">

				SELECT blogID
				FROM userblogs
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">

				<cfif isDefined("arguments.blogID")>
					AND blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">
				</cfif>

			</cfquery>

			<!--- // Found? --->
			<cfif local.query.recordCount GT 0>
				<cfset result.status = true />
			</cfif>

			<cfcatch>

				<!--- :: degrade gracefully :: --->
				<cfset result.query.recordCount = 0>
				<cfset result.message = 999>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: getRecentBlogs", errorCatch = variables.cfcatch  )>

			</cfcatch>

		</cftry>

		<cfreturn result />

	</cffunction>

	<!--- :: Check Authorization :: --->
	<cffunction name="isAuth" returntype="Any" access="package">
		<cfargument name="auth_token" type="string"  required="true">
		<cfargument name="userID"     type="numeric" required="true">

		<cfset local.attributes.auth_token = arguments.auth_token >
		<cfset local.attributes.userID = arguments.userID >
		<cfset local.attributes.authorize = true >

 		<!--- <cfset obj = createObject("component", "resources.authorize")>
        <cfset isAuthorized = obj.get(argumentCollection=local.attributes).getData()> --->

		<cfset isAuthorized = httpRequest( methodName = 'GET', endPointOfURL = '/authorize', timeout = 3000, parameters = local.attributes ) >
		
		<cfif structKeyExists(isAuthorized, "filecontent") AND isJSON(isAuthorized.filecontent) >
			
			<cfset authorize = deserializeJSON(isAuthorized.filecontent)>
			<cfreturn authorize.SESSION_AVAILABLE />

		<cfelse>

			<cfreturn false />
			
		</cfif>

	</cffunction>

	<!--- ::cfcatch errormessage:: --->
	<cffunction name="errorMessage" returntype="Any" access="public">
		<cfargument name="message" 	type="string" 	required="false">
		<cfargument name="error" 	type="any" 		required="false">

		<cfset requestUrl = listToArray(CGI.request_url, '/')>

		<cfif listfindnocase("api.yummienation.dev,qa-api.yummienation.com,dev.yummienation.com", CGI.HTTP_HOST) >

			<cfreturn arguments.error>

		<cfelse>

			<cfmail
		    	to 	     = "dev@yummienation.com"
		    	from 	 = "#application.supportEmail#"
				subject  = "Production Error Details"
		    	type 	 = "html"
				username = "#application.emailUsername#"
				server   = "#application.emailServer#"
				port     = "#application.emailServerPortSMTP#"
				usessl   = "#application.emailServerSSL#"
				password = "#application.emailPassword#">
				<h1> Exception </h1>
				<cfdump var="#arguments.error#" />				
	 		</cfmail>

			<cfreturn application.messages[arguments.message]>

		</cfif>

	</cffunction>

	<cfscript>

		private function httpRequest( string methodName, string endPointOfURL, numeric timeout, struct parameters ) {
/*
            obj = createObject("component", "resources."&replace(endPointOfURL,"/",""));
            returnData = invoke(obj, methodName, {argumentCollection=parameters}).getData();
            return returnData;
*/

			authorizeToken = "Basic "&toBase64("#Application.taffyBasicAuth#");

			http = new http();

			http.setTimeOut( timeout );

			http.setUrl( application.taffyRootURL & endPointOfURL );
			http.setMethod( methodName );

			http.addParam(type="header", name="Authorization", value="#authorizeToken#");

			if( structKeyExists( arguments, "parameters" ) AND structCount( parameters ) ) {

				if( methodName EQ 'POST' ) {
					for( fieldName in parameters ) {
						http.addParam(type="formField", name="#fieldName#", value="#structFind( parameters, fieldName )#");
					}
				}

				if( methodName EQ 'GET' OR methodName EQ 'DELETE' OR methodName EQ 'PUT' AND structKeyExists(arguments, "parameters") ) {

					for( fieldName in parameters ) {

						if( fieldName EQ "filters" OR fieldName EQ "pagination" ){

							http.addParam( type="url", name="#fieldName#", value="#serializeJSON(structFind( parameters, fieldName ))#");

						} else{

							http.addParam( type="url", name="#fieldName#", value="#structFind( parameters, fieldName )#");
						}
					}

				}

			}

			returnData = http.send().getPrefix();
			return returnData;
		}

	</cfscript>

</cfcomponent>
