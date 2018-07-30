<cfcomponent extends="taffyAPI.base" taffy:uri="/publisherAdTags/" hint="">

	<cffunction name="GET" access="public" output="false" auth="true" hint="Used to get the publisher tag details" >
		<cfargument name="userID" 		type="numeric" required="true" hint="userID">
		<cfargument name="blogID" 		type="numeric" required="true" hint="Blog ID">
		<cfargument name="auth_token"   type="string"  required="true"  hint="User authorization token (auth_token).">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<!--- // Get publishersMeta List --->
		<cfset local.attributes = StructNew() >
		<cfset local.attributes.userID = arguments.userID >		
		<cfset local.attributes.auth_token = arguments.auth_token >

		<cfset local.callPublisherMeta = httpRequest( methodName = 'GET', endPointOfURL = '/publishersMeta/', timeout = 3000, parameters = local.attributes ) >
		<cfset local.getPublisherMeta  = deserializeJson(local.callPublisherMeta.filecontent) >
  		

  		<!--- // Get active AD UNITs List --->
		<cfset local.callAdUnits = httpRequest( methodName = 'GET', endPointOfURL = '/adUnits/', timeout = 3000 ) >
		<cfset local.getAdUnits  = deserializeJson(local.callAdUnits.filecontent) >
		

		<cftry>

			<cfset result.query = queryNew("AdUnitName,AdUnitID,AdUnitCODE,AdUnitNOSCRIPT,AdTag", "varchar,integer,varchar,varchar,varchar") >
			<cfset result.blowFoldRight = queryNew("AdUnitName,AdUnitID,AdUnitCODE,AdUnitNOSCRIPT,AdTag", "varchar,integer,varchar,varchar,varchar") >

			<!--- // START: Loop through ad units --->

			<cfloop array="#local.getAdUnits.dataset#" index="adUnit">

				<!--- // START: Ad Tags isVisible? --->
				<cfif adUnit.isVisible EQ 1 AND adUnit.locationID EQ 3>

					<!--- // START: Ad Tags found?--->
					<cfif StructKeyExists(local.getPublisherMeta.publishers_Meta, adUnit.adUnitName)>
						
						<!--- Above the Fold - Right --->
						<cfset local.thisAdUnitName 	= adUnit.adUnitName>
						<cfset local.thisAdUnitID   	= 0>
						<cfset local.thisAdUnitCODE 	= "">
						<cfset local.thisAdUnitNOSCRIPT = "">
						
						<cfloop array="#local.getPublisherMeta.dataset#" index="publisherMeta">						
							
							<cfif publisherMeta['meta_key'] EQ local.thisAdUnitName AND publisherMeta['blogID'] EQ arguments.blogID>
								<cfset local.thisAdUnitID = publisherMeta['meta_value'] >
							</cfif>
							
							<cfif publisherMeta['meta_key'] EQ "CODE - " & local.thisAdUnitName AND publisherMeta['blogID'] EQ arguments.blogID >
								<cfset local.thisAdUnitCODE = publisherMeta['meta_value'] >
							</cfif>	

						</cfloop>
						
						<cfscript>

							local.adTag = adUnit.adUnitTemplate;					
						 	local.adTag = ReplaceNoCase(local.adTag, "__blogID__", arguments.blogID, "ALL");
							local.adTag = ReplaceNoCase(local.adTag, "__userID__", arguments.userID, "ALL");						
							local.adTag = ReplaceNoCase(local.adTag,  "__account_id__",local.getPublisherMeta.publishers_Meta["account_id"], "ALL");
							local.adTag = ReplaceNoCase(local.adTag, "__site_id__", local.getPublisherMeta.publishers_Meta["site_id"], "ALL");						
							local.adTag = ReplaceNoCase(local.adTag, "__adUnitId__", local.thisAdUnitID, "ALL"); 

						</cfscript>	

						<cfset queryAddRow(result.query)>
						<cfset querySetCell(result.query, "AdUnitName", local.thisAdUnitName)>
						<cfset querySetCell(result.query, "AdUnitID", local.thisAdUnitID )>
						<cfset querySetCell(result.query, "AdUnitCODE", HtmlEditFormat(local.adTag) )>
						<cfset querySetCell(result.query, "AdUnitNOSCRIPT", local.thisAdUnitNOSCRIPT)>
						<cfset querySetCell(result.query, "AdTag", HtmlEditFormat(local.adTag))>
					
					</cfif>
					<!--- // END: Ad Tags found?--->
				</cfif>
				<!--- // END: Ad Tags isVisible? --->
			</cfloop>		
			<!--- // END: Loop through ad units --->


			<!--- // START: Loop through ad units --->
			<cfloop array="#local.getAdUnits.dataset#" index="adUnit">
				
				<!--- // START: Ad Tags isVisible? --->
				<cfif adUnit.isVisible EQ 1 AND adUnit.locationID EQ 9>
					
					<!--- // START: Ad Tags found? --->
					<cfif StructKeyExists(local.getPublisherMeta.publishers_Meta, adUnit.adUnitName)>

						<!--- Below the Fold - Right --->
						<cfset local.thisAdUnitName 	= adUnit.adUnitName>
						<cfset local.thisAdUnitID   	= 0>
						<cfset local.thisAdUnitCODE 	= "">
						<cfset local.thisAdUnitNOSCRIPT = "">
						
						<cfloop array="#local.getPublisherMeta.dataset#" index="publisherMeta">

							<cfif publisherMeta['meta_key'] EQ local.thisAdUnitName AND publisherMeta['blogID'] EQ arguments.blogID>
								<cfset local.thisAdUnitID = publisherMeta['meta_value'] >

							</cfif>
							
							<cfif StructKeyExists(local.getPublisherMeta.publishers_Meta, "CODE - #local.thisAdUnitName#") AND publisherMeta['blogID'] EQ arguments.blogID >
								<cfset local.thisAdUnitCODE = publisherMeta['meta_value'] >
							</cfif>	

						</cfloop>

						<!--- // START: Ad Unit ID valid? --->
						<cfif local.thisAdUnitID GT 0>						
							
							<cfscript>
								local.adTag = adUnit.adUnitTemplate;					
							 	local.adTag = ReplaceNoCase(local.adTag, "__blogID__", arguments.blogID, "ALL");
								local.adTag = ReplaceNoCase(local.adTag, "__userID__", arguments.userID, "ALL");						
								local.adTag = ReplaceNoCase(local.adTag,  "__account_id__",local.getPublisherMeta.publishers_Meta["account_id"], "ALL");
								local.adTag = ReplaceNoCase(local.adTag, "__site_id__", local.getPublisherMeta.publishers_Meta["site_id"], "ALL");						
								local.adTag = ReplaceNoCase(local.adTag, "__adUnitId__", local.thisAdUnitID, "ALL");
							</cfscript>
							
						
							<cfset queryAddRow(result.blowFoldRight)>
							<cfset querySetCell(result.blowFoldRight, "AdUnitName", local.thisAdUnitName)>
							<cfset querySetCell(result.blowFoldRight, "AdUnitID", local.thisAdUnitID )>
							<cfset querySetCell(result.blowFoldRight, "AdUnitCODE", HtmlEditFormat(local.adTag) )>
							<cfset querySetCell(result.blowFoldRight, "AdUnitNOSCRIPT", local.thisAdUnitNOSCRIPT)>
							<cfset querySetCell(result.blowFoldRight, "AdTag", HtmlEditFormat(local.adTag))>

						</cfif>
						<!--- // END: Ad Unit ID valid? --->
					</cfif>
					<!--- // START: Ad Tags found? --->
				</cfif>
				<!--- // END: Ad Tags isVisible? --->
			</cfloop>
			<!--- // END: Loop through ad units --->		
	 
			<cfcatch>

				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)> 
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /publisherAdTags GET", errorCatch = variables.cfcatch )>	

			  	<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
			
		</cftry>

		<cfset result.status  = true />
		<cfset result.message =application.messages['publisherAdTags_get_found_success']  />

	  	<cfset logAction( actionID = 2004, extra = "method: /publisherAdTags/ GET" )>

		<cfreturn representationOf(result).withStatus(200) />
		
	</cffunction>	

</cfcomponent>