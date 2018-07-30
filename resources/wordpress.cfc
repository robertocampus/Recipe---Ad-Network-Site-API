<!---
	
	This Componet contains functions to connect a Wordpress plugin (in development) with our backend via jSON API calls.
	
	After a user install the plug-in on Wordpress , they have to "connect" their Wordpress account with their BLOG ID on our database.
	So, in Wordpress, the first thing we ask them to do is to enter their "BLOG ID" or an "access code" in a form and click submit. The user gets the blog id or access code from within our user UI.
	
	At that point, an Ajax call from Wordpress will invoke an API method on our server and try to verify if the BLOG ID or access code are valid. 
	
	If they are valid, it will return an object with HTML tags for Wordpress to save in its database for use by the plug-in.
	
	Later, we will add a lot more stuff to this, but for now, we just need to API to handle the initial verification and respond with a true/false reply and an object (if true).
	
	
--->


<cfcomponent extends="taffyAPI.base" taffy:uri="/wordpress/{blogID}/" hint="methods used to verify blog and to retrieve ad units code for use by wordpress plugin">

	<cffunction name="GET" access="public" hint="Returns connect blog status variables and adunits array" returntype="Struct" output="true" >
		<cfargument name="blogID" 		type="string" 	required="yes" 	hint="Blog ID (numeric)">
		<cfargument name="accessCode" 	type="string" 	required="no"  	hint="Access Code (string)" default="" >
		<cfargument name="blogURL" 		type="string" 	required="yes" 	hint="URL of blog (string)">
		<cfargument name="pluginID"  	type="string" 	required="yes" 	hint="ID of plug-in (numeric)">
		<cfargument name="debug"  		type="string" 	required="no"  	hint="1/0 used for deubbing" default="" >		
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />

		<cftry>

			<cfscript>
				local.attributes.filters = StructNew();
				local.attributes.filters.statusID 	= "3,4";
				local.attributes.filters.active 	= 1;
				local.attributes.filters.SearchBlogID = arguments.blogID;
				local.attributes.filters.publisherStatusID = "1,2,3";
				local.attributes.filters.SearchBlogURL = arguments.blogURL;

				local.attributes.pagination				= StructNew();
				local.attributes.pagination.pageNum		= 1;
				local.attributes.pagination.maxRows 	= 1;
				local.attributes.pagination.orderCol 	= "blogTitle";
				local.attributes.pagination.orderDir 	= "ASC"; 
			</cfscript>

			<cfset result.query = queryNew("adUnitID, adUnitName, adUnitType, accountID, siteID, isVisible, adTagHTML", "varchar, varchar, varchar, varchar, varchar, integer, varchar")>

			<!--- Find a blog using GET method of Blogs.cfc  --->
			<cfset getBlog = httpRequest( methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters = local.attributes ) >

			<cfif getBlog.Statuscode EQ "200 OK" AND len(getBlog.FileContent)>

				<cfset getBlogAsStructure = deserializeJSON(getBlog.FileContent) >

				<cfif arrayLen(getBlogAsStructure.dataSet)>
					
					<!--- Generate unique UUID (connectID) for use by wordpress plug-in to store security token --->
					<cfset result.connectID = CreateUUID()>

					<cfset updateBlog.connectID = result.connectID >
					<cfset updateBlog.pluginID = arguments.pluginID >
					
					<!--- update pluginID and connectID of a blog using PUT method of Blog.cfc  --->
					<cfset updateBlog = httpRequest( methodName = 'PUT', endPointOfURL = '/blog/#arguments.BlogID#', timeout = 3000, parameters = updateBlog )>

					<cfset result.UserID = getBlogAsStructure.dataset[1].userid >

					<cfset getPublisherMeta.UserID = result.UserID >
					<cfset getPublisherMeta.NotAuthorize = false >

					<!--- getting metaData for particular user --->
					<cfset getPublisherMeta = httpRequest( methodName = 'GET', endPointOfURL = '/publishersMeta/', timeout = 3000, parameters = getPublisherMeta ) >

					<cfset getPublisherMeta = deserializeJSON(getPublisherMeta.FileContent)>

					<!--- getting Ad Units --->
					<cfset getAdUnits = httpRequest( methodName = 'GET', endPointOfURL = '/adUnits/', timeout = 3000 ) >

					<cfset getAdUnits = deserializeJSON(getAdUnits.FileContent) >

					<cfloop index="AdUnitsposition" from="1" to="#arrayLen(getAdUnits.dataSet)#">
						<cfif getAdUnits.dataSet[#AdUnitsposition#].isVisible EQ 1 AND getAdUnits.dataSet[#AdUnitsposition#].locationID EQ 3>

							<cfset local.thisAdUnitName 	= getAdUnits.dataSet[#AdUnitsposition#].adUnitName>
							<cfset local.thisAdUnitID   	= 0>
							<cfset local.thisAccountID 		= 0>
							<cfset local.thisSiteID 		= 0>
							<cfset local.adUnitType 		= "">

							<cfloop index="publishersMetaPosition" from="1" to="#arrayLen(getPublisherMeta.dataSet)#" >
								<cfset PublisherMeta = getPublisherMeta.dataSet[#publishersMetaPosition#] >

								<cfif PublisherMeta.META_KEY EQ local.thisAdUnitName AND PublisherMeta.blogID EQ arguments.blogID >
									<cfset local.thisAdUnitID = PublisherMeta.META_VALUE >
								</cfif>
								<cfif PublisherMeta.META_KEY EQ 'account_id' AND PublisherMeta.blogID EQ arguments.blogID >
									<cfset local.thisAccountID = PublisherMeta.META_VALUE >
								</cfif>
								<cfif PublisherMeta.META_KEY EQ 'site_id' AND PublisherMeta.blogID EQ arguments.blogID >
									<cfset local.thisSiteID = PublisherMeta.META_VALUE >
								</cfif>
							</cfloop>

							<cfset local.adTagHTML = getAdUnits.dataSet[#AdUnitsposition#].adUnitTemplate >
							<cfset local.adUnitType = getAdUnits.dataSet[#AdUnitsposition#].adUnitType >
							<cfset local.adTagHTML = replaceNoCase(local.adTagHTML, '"__blogID__"', arguments.blogID, "ALL") >
							<cfset local.adTagHTML = replaceNoCase(local.adTagHTML, '"__UserID__"', result.UserID, "ALL")>
							<cfset local.adTagHTML = replaceNoCase(local.adTagHTML, '"__account_id__"', local.thisAccountID, "ALL")>
							<cfset local.adTagHTML = replaceNoCase(local.adTagHTML, '"__site_id__"', local.thisSiteID, "ALL") >
							<cfset local.adTagHTML = ReplaceNoCase(local.adTagHTML, '"__adUnitId__"', local.thisAdUnitID, "ALL") >
							<cfset local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__adUnitName__", local.thisAdUnitName, "ALL") >

							<cfset queryAddRow(result.query, 1) >
							<cfset querySetCell(result.query, "adUnitID", local.thisAdUnitID) >
							<cfset querySetCell(result.query, "adUnitName", local.thisAdUnitName) >
							<cfset querySetCell(result.query, "adUnitType", local.adUnitType) >
							<cfset querySetCell(result.query, "accountID", local.thisAccountID) >
							<cfset querySetCell(result.query, "siteID", local.thisSiteID) >
							<cfset querySetCell(result.query, "isVisible", 1) >
							<cfset querySetCell(result.query, "adTagHTML", local.adTagHTML) >

						</cfif>
					</cfloop>

					<cfset result.status = true >
					<cfset result.message = "success" />
			  		<cfset logAction( actionID = 1006, extra = "method: /wordpress/{blogID}/GET" )>
					
				<cfelse>
					<cfset logAction( actionID = 3003, extra = "method: /wordpress/{blogID}/GET" )>

					<cfreturn noData().withStatus(404) />
				</cfif>
			<cfelse>
				<cfreturn noData().withStatus(404) />
			</cfif>

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 3002, extra = "method: /wordpress/{blogID}/GET", errorCatch = variables.cfcatch )>

				<cfreturn noData().withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset result.status = true />
		<cfset result.message = 'success' />
		
		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>

	<!--- Method :: POST --->
	<!--- TO BE DEFINED --->
	<cffunction name="POST" access="public" output="false" returnformat="JSON" returntype="Struct" hint="Return users created DATA details by <code> POST </code> method">
		<cfargument name="test" 			required="true"		type="string"	/>
		 
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>

<!---   
		Save this Wordpress GET function call to the logs.  *you have to add a new entry in val_action for this and then reference it when you save the log action*
		 	See line ** for an example - the actionID there needs to be changed also...
		 	
		 	Please note: In general, for all our API calls, we need to log both successfull and unsuccesfull calls to each method 
		 				 and make sure we use the correct "ActionID". See the "val_actions" table for examples. Feel free to add new "actions" if there isn't one already.
		 				 
		 Now...
		 
		) Check if the blog ID is numeric -- true?
		
		) Check if the BLOG ID and BLOG URL parameters match a record in the "blogs" table. You can pass those as filters. 
			You must also check if "statusID" column is be "3 or 4" and that the blog "active" column is 1
			
			( invoke a "get blog" method in the "blogs" component, see example below - you may have to change stuff around for this to work:
			
			<cfscript>
			local.attributes.filters = StructNew();
			local.attributes.filters.statusID 	= "3,4";
			local.attributes.filters.active 	= 1;
			
			local.attributes.paging				= StructNew();
			local.attributes.paging.pageNum		= 1;
			local.attributes.paging.maxRows 	= 1;
			local.attributes.paging.orderCol 	= "blogTitle";
			local.attributes.paging.orderDir 	= "ASC"; 
			
			// invoke getBlogDetailsByFilter method in dataObj component 
			local.getBlogDetailsByFilter = application.dataObj.getBlogDetailsByFilter( filters = local.attributes.filters, paging = local.attributes.paging ); 
			</cfscript>
			
			did the method above return true? 
			
		)  Ok, blogID is found, 
		
		) compare URL passed in arguments with URL of the blog as returned by the getBlogDetailsByFilter method. If it matches, move on to next step...
		
		) Now, we need to make sure the blog has been previously submitted into our publisher program. We do that by checking the "publisherStatusID" column (from the query or get blog method you did earlier). 
			
			if  publisherStatusID is NOT 1,2 or 3 then this blog is not in the publisher program. Return "not eligible" as the response code. End here.
		
			if the publisherStatusID is 1,2 or 3 move to the next step ->
		
		) Update the "pluginID" column for this blog in the "blogs" table with the "plugInID" passed in from the argument. 
			
			Please note: Try to do this by invoking the "UPDATE BLOG" method in the blog component. You may have to add some logic to that function to actually update the "plugInID" column.
		
		) Now, we need to get the AD Units HTML code for this blog and pass add them to the response object. You can name the object "adunits" or something similar.
			
			First, take the "getPublisherMeta" function in the /api/_data.publishers.cfm" component and move it somewhere in the /api/v2/ area, so we can invoke it from here.
		 	
		 	Now, invoke it (replace "???" based on where you put this):					 							
			<cfset local.getPublisherMeta = ???.getPublisherMeta( userID = userID)>
			
			Second, run this function to get a list of active ad units. Again, take the "getAdUnits" function in the /api/_data.publishers.cfm" component
			and move it somewhere in the /api/v2/ code, so we can use it from here.
		 	
		 	Now, invoke it (replace "???" based on where you put this):
			<cfset local.getAdUnits = ???.getAdUnits()><!--- // Get active AD UNITs List --->
			
			Now, use the code below (needs to be adjustd to work here of course) to loop through the ad units and add to the "adunits" object to pass back to Wordpress via jSON:
			
			<!--- // START: Loop through ad units --->
			<cfloop query="local.getAdUnits.query">
				<!--- // START: Ad Tags isVisible? --->
				<cfif isVisible EQ 1 AND locationID EQ 3>
					<!--- // START: Ad Tags found? --->
					<cfif StructKeyExists(local.getPublisherMeta, adUnitName)>
						<cfset local.thisAdUnitName 	= adUnitName>
						<cfset local.thisAdUnitID   	= 0>
						<cfset local.thisAdUnitCODE 	= "">
						<cfset local.thisAdUnitNOSCRIPT = "">
						
						<cfloop query="local.getPublisherMeta.query">
							<cfif META_KEY EQ thisAdUnitName AND blogID EQ local.blogID>
								<cfset local.thisAdUnitID = META_VALUE>
							</cfif>
							<cfif META_KEY EQ "CODE - " & local.thisAdUnitName AND blogID EQ local.blogID>
								<cfset local.thisAdUnitCODE = META_VALUE>
							</cfif>	
						</cfloop>
						
						
						<cfscript>
							// keep adding the various ad unit parameters value pairs to the "adunits" object, do something like this:
						
							// create the final HTML ad tag (using a template and replacing with actual parameters)
							local.adTagHTML = adUnitTemplate;
						 	local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__blogID__", local.blogID, "ALL");
							local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__userID__", local.userID, "ALL");
							local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__account_id__", local.getPublisherMeta["account_id"], "ALL");
							local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__site_id__", local.getPublisherMeta["site_id"], "ALL");
							local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__adUnitId__", local.thisAdUnitID, "ALL"); 
							local.adTagHTML = ReplaceNoCase(local.adTagHTML, "__adUnitName__", local.adUnitName, "ALL");
							
							
							
							/*
							 // ultimately, the JSON for eaach ad unit needs to be like this:
							 
							 "adUnitID" : "#local.thisAdUnitID#",
					         "adUnitName": "#local.adUnitName#",
					         "adUnitType": "IAB",
					         "accountID": #local.getPublisherMeta["account_id"]#,
					         "siteID": #local.getPublisherMeta["site_id"]#,
					         "isVisible": 1,
					         "adTagHTML" : "#local.adTagHTML#"
							 */
							
						</cfscript>
						 
					</cfif>
				</cfif>
				<!--- // END: Ad Tags isVisible? --->
			</cfloop>
			<!--- // END: Loop through ad units --->
			
		) Next, set the result.status = true
		
		) Return the object with the ad units and the response...
		
--->