<cfcomponent extends="taffyAPI.base" taffy_uri="/machineL/" hint="Using this we can able to detect which type of image is being uploaded">

	<cffunction name="GET" access="public" output="false" hint="returns the confidence value of the image">

		<cfargument name="imageID" type="numeric" required="true" hint="image id of the image">

		<cfset result = structNew()>
		<cfset result['message'] = ''>
		<cfset result['error'] = true>
		<cfset result['status'] = false>

		<cfquery name="local.query" datasource="#variables.datasource#">

			SELECT entityID,
					entityTypeID,
					imagePath 
				 FROM images 
				 WHERE imageID = <cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">

		</cfquery>

		<cfif local.query.recordCount>
			
			<cfhttp method="GET" url="http://gateway-a.watsonplatform.net/calls/url/URLGetRankedImageKeywords" result="data">

				<cfhttpparam type="url" name="apikey" value="2dcadeff88fbc5e0b10fd8996c5ccd1b5299239b"/>
				<cfhttpparam type="url" name="url"  value="#local.query.imagePath#">
				<cfhttpparam type="url" name="outputMode" value="json"/>
				
			</cfhttp>

			<cfset imageDetails = deserializeJSON(data.filecontent).imagekeywords>

			<cfset isValidImage = 0>

			<cfswitch expression="#local.query.entityTypeID#">

				<cfcase value="4">
			
					<cfloop array="#imageDetails#" index="element">

						<cfif structKeyExists(element,'text') AND structFind(element,'text') EQ 'person' AND structFind(element,'score') GTE 0.9>
							<cfset isValidImage = 1>
							<cfset result['message'] = 'This image contains user picture'>
							<cfset result['error']   = false>
							<cfset result['status']  = true>

							<cfif isValidImage EQ 1>

								<cfquery name="local.qry" datasource="#variables.datasource#">
									
									INSERT INTO images_keywords ( imageID,keyword,score )  VALUES (
																			<cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">,
																			<cfqueryparam value="person" cfsqltype="cf_sql_varchar">,
																			<cfqueryparam value="#structFind(element,'score')#" cfsqltype="cf_sql_integer">
																		)

								</cfquery>

								<cfreturn representationOf(result).withStatus(200)>

							</cfif>

						</cfif>


					</cfloop>

					<cfif isValidImage EQ 0>

						<cfquery name="local.qry" datasource="#variables.datasource#">
									
							INSERT INTO images_keywords ( imageID,keyword,score ) VALUES (
																	
																	<cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">,
																	<cfqueryparam value="person" cfsqltype="cf_sql_varchar">,
																	<cfqueryparam value="0" cfsqltype="cf_sql_integer">

																)

						</cfquery>


						<cfset result['message'] = 'Sorry we are not able detect an user picture here.Please upload user picture'>

						<cfreturn representationOf(result).withStatus(406)>

					</cfif>

				</cfcase>

				<cfcase value="10">
						
					<cfloop array="#imageDetails#" index="element">

						<cfif structKeyExists(element,'text') AND structFind(element,'text') EQ 'food' AND structFind(element,'score') GTE 0.85>

							<cfset isValidImage = 1>
							<cfset result['message'] = 'This image contains recipe picture'>
							<cfset result['error'] 	 = false>
							<cfset result['status']  = true>

							<cfif isValidImage EQ 1>

								<cfquery name="local.qry" datasource="#variables.datasource#">
									
									INSERT INTO images_keywords ( imageID,keyword,score )VALUES (
																			<cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">,
																			<cfqueryparam value="food" cfsqltype="cf_sql_varchar">,
																			<cfqueryparam value="#structFind(element,'score')#" cfsqltype="cf_sql_float">
																		)

								</cfquery>

								<cfreturn representationOf(result).withStatus(200)>

							</cfif>

						</cfif>

					</cfloop>
					
					<cfif isValidImage EQ 0>

						<cfquery name="local.qry" datasource="#variables.datasource#">
									
							INSERT INTO images_keywords ( imageID,keyword,score ) VALUES (
																	<cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">,
																	<cfqueryparam value="food" cfsqltype="cf_sql_varchar">,
																	<cfqueryparam value="0" cfsqltype="cf_sql_integer">
																)

						</cfquery>

						<cfset result['message'] = 'Sorry we are not able detect an recipe picture here.Please upload recipe picture'>

						<cfreturn representationOf(result).withStatus(406)>

					</cfif>

				</cfcase>

			</cfswitch>

		<cfelse>

			<cfreturn noData().withStatus(404)>

		</cfif>

	</cffunction>

</cfcomponent>
