<cfcomponent extends="taffyAPI.base" taffy:uri="/blog/{id}" hint="Using this user can able to <code>Get</code> a single blog's details by passing BlogID. Can also able to <code>Update</code> & <code>Delete</code> an existing blog using BlogID.">
	
	<cffunction name="GET" access="public" hint="Return Blog Details - Find by ID" output="false">
	
		<cfargument name="ID" type="numeric" required="true" hint="Blog ID">	
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
		<cfset result['error']		="">

		<cftry>

		    <cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
	   
		    <cfquery datasource="#variables.dataSource#" name="result.query"><!--- cachedwithin="#CreateTimeSpan(0,0,15,0)#" --->
				SELECT 
					B.blogID
					,B.blogTitle
					,B.blogURL
					,(SELECT GROUP_CONCAT( t.tagName )
						FROM tags AS t
						INNER JOIN tagging AS tg ON tg.tagID = t.tagID
						WHERE tg.entityID = B.blogID
						AND tg.entitytypeID = <cfqueryparam value="3" cfsqltype="cf_sql_integer"> ) AS 'blogTags'
					,B.blogDescription
					,B.blogDateCreated
					,B.categoryID
					,B.blogIsPublisher
					,B.publisherStatusID
					,B.blogThumbnailStatus
					,B.blogRss
					,B.publisherDateApproved
					,B.privacyPolicyURL
					,B.facebookPageURL
					,CASE B.BlogThumbnailStatus	
						WHEN 0 THEN 'No'	
						WHEN 1 THEN 'Yes'
					END AS BlogThumbnailStatusName
					,CONCAT( I.imagePath, '/', I.imageName ) AS 'blog_FullSize_Image'
					,CONCAT( I.imagePath, '/', I.imageThumbFileName ) AS 'blog_Thumb_Image'
					,CONCAT( I.imagePath, '/', I.imageFileNameHalf ) AS 'blog_mini_Image'
					,VC.categoryName
					,VSC.sourceName
					,VS.statusName
					,U.userID
					,U.userFirstName AS authorFirstName
					,U.userLastName AS authorLastName
					,U.userName AS authorUserName
					,U.isInfluencer AS 'isInfluencer'
					,U.userEmail AS authorEmail
		        	,CASE U.userGender	
						WHEN '0' THEN 'N/A'	
						WHEN 'M' THEN 'Male'
						WHEN 'F' THEN 'Female'
					END AS authorGenderName
		        	,U.userAbout AS authorAbout
					,L.locationName
					,G.languageName
					,U.userAddressLine1 AS authorAddressLine1
					,U.userAddressLine2 AS authorAddressLine2
					,U.userAddressLine3 AS authorAddressLine3
					,U.userCity AS authorCityName
					,S.stateName AS authorStateName
					,SP.sponsorID
					,C.countryFullName AS authorCountryName
					,CONCAT( UI.imagePath, '/', UI.imageName ) AS 'author_FullSize_Image'
					,CONCAT( UI.imagePath, '/', UI.imageThumbFileName ) AS 'author_Thumb_Image'
					,CONCAT( UI.imagePath, '/', UI.imageFileNameHalf ) AS 'author_mini_Image'
					,evc.count AS blogHitsAllTime
					,B.hitsWeekly AS blogHitCount
					,( SELECT max( meta_value ) FROM users_meta WHERE meta_key LIKE '%user_total_followers%' AND userID=U.userID ) AS 'author_total_followers'
					,( SELECT max( meta_value ) FROM users_meta WHERE meta_key LIKE '%user_total_posts%' AND userID=U.userID ) AS 'author_total_posts'
					,( SELECT count(R.recipeID) from recipes R WHERE R.userID=U.userID ) AS TotalRecipes
					,( SELECT TRUNCATE(AVG(r.rating),1) FROM ratings r WHERE r.entitytypeID = ( SELECT entitytypeID FROM val_entityType WHERE entityTypeName = "blog" ) ) AS blogRating
					,( SELECT COUNT(entitytypeID) FROM ratings r WHERE r.entitytypeID = ( SELECT entitytypeID FROM val_entityType WHERE entityTypeName = "blog" ) ) AS blogRatingCount
					,(SELECT count(userID) FROM users_follow WHERE entityID = B.blogID AND entitytypeID = 3 AND followStatus = 1) AS 'blog_totalFollowers'
				FROM blogs B
					LEFT JOIN val_category VC on VC.categoryID = B.categoryID
					LEFT JOIN val_source VSC on VSC.sourceID = B.sourceID
					LEFT JOIN val_status VS on VS.statusID = B.statusID
					LEFT JOIN val_publisherstatus VPS on VPS.publisherStatusID = B.publisherStatusID
					LEFT JOIN userblogs UB  on UB.BlogID = B.BlogID
					LEFT JOIN users U on U.userID = UB.UserID
					LEFT JOIN sponsors SP ON SP.userID = U.userID AND SP.active = 1
					LEFT JOIN val_countries C on C.countryID = U.userCountryID
					LEFT JOIN val_language G on G.languageID = B.languageID
					LEFT JOIN val_states S on S.stateID = U.userStateID
					LEFT JOIN val_location L on L.locationID = U.locationID
					LEFT JOIN images I on I.entityID = B.blogID	AND I.entitytypeID = 3
					LEFT JOIN images UI on UI.entityID = U.userID	AND UI.entitytypeID = 4
					LEFT JOIN entityViewsCount evc on evc.entityID = B.blogID AND evc.entityTypeID = 3
				WHERE 
					  B.active = 1
					  AND B.blogID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.ID#">
				GROUP BY B.blogID
			</cfquery>

			<!--- // Any Records Found? --->

			<cfif result.query.recordCount EQ 0>
				<cfset result.message = application.messages['blog_get_found_error'] />
				<cfreturn representationOf(result).withStatus(404) />

			</cfif>
		   
			<cfset local.userSocialDetails = application.accountObj.getUserSocialDetails(result.query.userID)>

			<cfif local.userSocialDetails.status EQ true>
				<cfset result.userSocialDetails = local.userSocialDetails.dataset>
			<cfelse>
				<cfset result.userSocialDetails = []>
			</cfif>

		  	<cfcatch>				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /blog/{id}/GET", errorCatch = variables.cfcatch  )>	
			  
			  	<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
	    </cftry>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['blog_get_found_success'] />

	  	<cfset local.tmp = logAction( actionID = 201, extra = "method: /blog/{id}/GET"  )>

		<cfreturn representationOf( result ).withStatus(200) />

	</cffunction>

	<cffunction name="PUT" access="public" output="false" hint="Update a blog" auth="true">
	
		<cfargument name="id" 				type="numeric" 	required="true" hint="Blog ID">
		<cfargument name="userID" 			type="numeric" 	required="true" hint="user ID">
		<cfargument name="auth_token" 		type="string" 	required="true" hint="auth_token of the user">
		<cfargument name="blogTitle" 		type="string" 	required="false">		
		<cfargument name="blogURL" 			type="string" 	required="false">
		<cfargument name="blogRSS" 			type="string" 	required="false">
		<cfargument name="blogDescription" 	type="string" 	required="false">
		<cfargument name="blogTags" 		type="string" 	required="false">
		<cfargument name="active" 			type="numeric" 	required="false" default="1">
		<cfargument name="imageID" 			type="numeric" 	required="false">
		<cfargument name="pluginID" 		type="string" 	required="false">
		<cfargument name="connectID" 		type="string" 	required="false">
		<cfargument name="languageID" 		type="string" 	required="false">
		<cfargument name="privacyPolicyURL"	type="string" 	required="false">
		<cfargument name="facebookPageURL"	type="string" 	required="false">
		<cfargument name="facebookPageID"	type="numeric" 	required="false">
		<cfargument name="publisherDateRequested" type="date" required="false">
		<cfargument name="publisherStatusID" type="numeric" required="false">
		
		<cfset var local.qry = "" />
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
		<cfset result['error']		= "">

		<cftry>

			<!--- START:: checking does the blog image is changed or not?--->
			<cfif structKeyExists(arguments, "imageID") AND arguments.imageID NEQ 0 >

				<cfset local.getBlogImage = application.dataObj.getImageDetails( entitytypeID = 3, entityID = arguments.id ) >

				<cfif local.getBlogImage.recordCount NEQ 0 >
					
					<cfset local.imageResponse = httpRequest( methodName = 'DELETE', endPointOfURL = '/image/#local.getBlogImage.imageID#', timeout = 3000 ) />
					
				</cfif>				

				<cfset local.attributes.entityID 	   = arguments.id />				
				<cfset local.attributes.entityTypeName = 'blog' />

				<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#arguments.imageID#', timeout = 3000, parameters = local.attributes ) />

				<cfset local.responseData = deserializeJSON(local.imageResponse.fileContent) >

				<cfif local.responseData.status EQ false >
					<cfthrow/>
				</cfif>

			</cfif>
			<!--- END:: checking does the blog image is changed or not?--->

			<!--- START:: checking does the facebook pageID is changed or not?--->
			<cfif structKeyExists(arguments, "facebookPageID") AND arguments.facebookPageID NEQ 0 >

				<cfset local.getfbPageID = application.dataObj.getfbPageID( blogID = arguments.facebookPageID ) >
				
				<cfif local.getfbPageID.recordCount NEQ 0 >

					<cfset structClear(local.attributes) >

					<cfset local.attributes.pageID = local.getfbPageID.facebookPageID />
					
					<cfset local.fbPageResponse = httpRequest( methodName = 'DELETE', endPointOfURL = '/facebookPage/', timeout = 3000, parameters = local.attributes ) />

				</cfif>


			</cfif>
			<!--- END:: checking does the facebook pageID is changed or not?--->
			
			<cfquery name="local.qry" datasource="#variables.datasource#" result="isUpdated" >
				UPDATE blogs 
					SET blogID = blogID

						<cfif structKeyExists(arguments, "blogTitle") AND len(arguments.blogTitle)>
							,blogTitle = <cfqueryparam value="#arguments.blogTitle#" cfsqltype="cf_sql_varchar">
							,blogSlug = <cfqueryparam value="#toSlug(arguments.blogTitle)#">
						</cfif>

						<cfif structKeyExists(arguments, "blogURL") AND len(arguments.blogURL)>
							,blogURL = <cfqueryparam value="#arguments.blogURL#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "blogRSS") AND len(arguments.blogRSS)>
							,blogRSS = <cfqueryparam value="#arguments.blogRSS#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "blogDescription") AND len(arguments.blogDescription)>
							,blogDescription = <cfqueryparam value="#arguments.blogDescription#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "active") AND len(arguments.active)>
							,active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_numeric">
						</cfif>

						<cfif structKeyExists(arguments, "pluginID") AND len(arguments.pluginID)>
							,pluginID = <cfqueryparam value="#arguments.pluginID#" cfsqltype="cf_sql_varchar">
						</cfif>
						
						<cfif structKeyExists(arguments, "connectID") AND len(arguments.connectID)>
							,connectID = <cfqueryparam value="#arguments.connectID#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "languageID") AND len(arguments.languageID)>
							,languageID = <cfqueryparam value="#arguments.languageID#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "privacyPolicyURL") AND len(arguments.privacyPolicyURL)>
							,privacyPolicyURL = <cfqueryparam value="#arguments.privacyPolicyURL#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "facebookPageURL") AND len(arguments.facebookPageURL)>
							,facebookPageURL = <cfqueryparam value="#arguments.facebookPageURL#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments, "facebookPageID") AND len(arguments.facebookPageID)>
							,facebookPageID = <cfqueryparam value="#arguments.facebookPageID#" cfsqltype="cf_sql_varchar">
						</cfif>

						<cfif structKeyExists(arguments,"publisherDateRequested") AND len(arguments.publisherDateRequested)>
							,publisherDateRequested = <cfqueryparam value="#arguments.publisherDateRequested#" cfsqltype="cf_sql_timestamp">
						</cfif>

						<cfif structKeyExists(arguments,"publisherStatusID") AND len(arguments.publisherStatusID)>
							,publisherStatusID = <cfqueryparam value="#arguments.publisherStatusID#" cfsqltype="cf_sql_numeric">
						</cfif>

						,blogDateModified = <cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">

					WHERE 
						blogID = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_numeric">	
			</cfquery>		
			
			<!--- START :: UPDATE blog tags in tagging table --->
			<cfif structKeyExists(arguments,'blogTags') AND arguments.blogTags NEQ ''>
				
				<cfset local.attributes.entityID 			= arguments.id>
				<cfset local.attributes.entityTypeID        = 3>
				<cfset local.attributes.userID 				= arguments.userID>
				<cfset local.attributes.auth_token 			= arguments.auth_token>
				<cfset local.attributes.tags 				= arguments.blogTags>

				<cfset blogtags = httpRequest( methodName = 'PUT', endPointOfURL = '/tag', timeout = 3000, parameters = local.attributes)>

			</cfif>
			<!--- END :: UPDATE blog tags in tagging table --->

			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /blog/{id}/PUT", errorCatch = variables.cfcatch )>

				<cfreturn representationOf( result.message ).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset statusCode = ( isUpdated.recordCount GT 0 ) ? 200 : 404 >

		<cfif statusCode EQ 200>
			
			<cfset result.message = application.messages['blog_put_update_success'] />

		<cfelse>

			<cfset result.message = application.messages['blog_put_update_error'] />


		</cfif>

	  	<cfset local.tmp = logAction( actionID = 80, extra = "method: /blog/{id}/PUT"  )>

		<cfreturn representationOf(result).withStatus(statusCode) />

	</cffunction>

	<cffunction name="DELETE" access="public" output="false" hint="Delete a blog with Blog ID">
		<cfargument name="id" type="numeric" required="yes" hint="Blog ID" />
		
		<cfset var local.qry = "" />
		<cfset result['message'] = "">
		<cfset result['error']   = "">

		<cftry>

			<cfquery name="local.qry" datasource="#variables.datasource#" result="isDeleted">
				DELETE FROM blogs WHERE blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#" />
			</cfquery>

			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /blog/{id}/DELETE", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>	


	  	<cfset local.tmp = logAction( actionID = 205, extra = "method: /blog/{id}/DELETE"  )>		

	  	<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

		<cfset result.message =statusCode EQ 200 ? application.messages['blog_delete_remove_success'] :application.messages['blog_delete_remove_error'] />

		<cfreturn representationOf(result).withStatus(statusCode) />

	</cffunction>

</cfcomponent>