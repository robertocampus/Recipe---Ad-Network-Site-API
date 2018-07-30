<cfcomponent extends="taffyAPI.base" taffy:uri="/facebookPage/" hint="Getting facebook pages and Inserting there needed details .">

	<cffunction name="GET" access="public" output="false" hint="Used to get the long life user access token.">		
		<cfargument name="accessToken" 	type="string"  required="true"  hint="facebook user accessToken got from the login" />
		<cfargument name="limit" 		type="numeric" required="false" hint="Number of facebook pages to get in a single call." />
		<cfargument name="after" 		type="string"  required="false" hint="To get the next set of pages." />
		<cfargument name="before" 		type="string"  required="false" hint="To get the previous set of pages." />
		<cfargument name="summary" 		type="string"  required="false" hint="To get the total number of pages." />

			<cfset result = structNew() />
			<cfset result['status'] = false />
			<cfset result['message'] = '' />

	        <cftry>
				
	        	<cfhttp url="https://graph.facebook.com/me/accounts?access_token=#arguments.accessToken#" result="fbPageDetails">
	        		
	        		<cfif structKeyExists(arguments, "limit") AND arguments.limit NEQ ''>
	        			<cfhttpparam type="url" name="limit" value="#arguments.limit#">	        			
	        		</cfif>
	        		<cfif structKeyExists(arguments, "after") AND arguments.after NEQ ''>
	        			<cfhttpparam type="url" name="after" value="#arguments.after#">	        			
	        		</cfif>
	        		<cfif structKeyExists(arguments, "before") AND arguments.before NEQ ''>
	        			<cfhttpparam type="url" name="before" value="#arguments.before#">	        			
	        		</cfif>
	        		<cfif structKeyExists(arguments, "summary") AND arguments.summary NEQ ''>
	        			<cfhttpparam type="url" name="summary" value="#arguments.summary#">	        			
	        		</cfif>

	        	</cfhttp>

				<cfif fbPageDetails.status_code NEQ 200>

					<cfset local.error = deserializeJSON(fbPageDetails.filecontent) >				
					<cfset result.message = local.error.error.message >
					<cfreturn representationOf(result).withStatus(406) />

				</cfif>

				<cfset result['pageDetails']  = deserializeJSON(fbPageDetails.filecontent)/>

				<cfloop array="#result['pageDetails'].data#" index="fbPages">

					<cfquery name="local.isConnected" datasource="#variables.datasource#">

						SELECT blogID,blogTitle,blogSlug FROM blogs
							WHERE facebookPageID =  <cfqueryparam value="#fbPages.id#" cfsqltype="cf_sql_varchar">

					</cfquery>
					
					<cfif local.isConnected.recordCount>

						<cfset structInsert(fbPages, "blogID", local.isConnected.blogID)>
						<cfset structInsert(fbPages, "blogTitle", local.isConnected.blogTitle)>
						<cfset structInsert(fbPages, "blogSlug", local.isConnected.blogSlug)>

						
					<cfelse>
	        			
						<cfset structInsert(fbPages, "blogID", '')>
						<cfset structInsert(fbPages, "blogTitle", '')>
						<cfset structInsert(fbPages, "blogSlug", '')>
						
					</cfif>

					<cfhttp url="https://graph.facebook.com/#fbPages.id#?access_token=#fbPages.access_token#&fields=likes,about&format=json" result="fbPageLikesDetails">
						
					<cfif fbPageLikesDetails.status_code NEQ 200>

						<cfset structInsert(fbPages, "likes", '')>

					<cfelse>

						<cfset structInsert(fbPages, "likes", deserializeJSON(fbPageLikesDetails.filecontent).likes)>

					</cfif>

				</cfloop>

				<cfcatch>

					<cfset result.message = errorMessage(message = 'socialfacebookpage_get_found_error', error = variables.cfcatch)>
					<cfset logAction( actionID = 1006, extra = "method: /facebookPage/GET", errorCatch = variables.cfcatch )>
					<cfreturn representationOf(result.message).withStatus(500) />

				</cfcatch>
			
			</cftry>			 

			<cfset result.status = true />
			<cfset result.message = application.messages['socialfacebookpage_get_found_success'] />

		  	<cfset logAction( actionID = 1005, extra = "method: /facebookPage/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

	<cffunction name="POST" access="public" output="true" returntype="Struct" hint="can insert the facebook page DATA using <code>POST</code>">
		<cfargument name="pageID"         	required="true"  type="string" 	default="" />
	    <cfargument name="facebookUserID"  	required="true"  type="string" 	default="" />
	    <cfargument name="pageName"		   	required="false" type="string" 	default="" />
	    <cfargument name="pageURL" 			required="false" type="string" 	default="" />    
	    <cfargument name="pageCategory" 	required="false" type="string" 	default="" />    
	    <cfargument name="pageAccessToken" 	required="true"  type="string" 	default="" />    

		    <cfset result = structNew() />
		    <cfset result['status'] = false />
		    <cfset result['message'] = ''>

		    <cftry>

		    	<cfquery name="local.facebookpage" datasource="#variables.datasource#" result="local.fbpage">
		    		SELECT 
		    			id 
		    			FROM social_login_facebook_pages
		    			WHERE pageID = <cfqueryparam value="#arguments.pageID#" cfsqltype="cf_sql_varchar">
		    	</cfquery>

		    	<cfif local.fbpage.recordCount NEQ 0 >

		    		<cfset result['id'] = local.facebookpage.id >
			        <cfset result['message'] = application.messages['socialfacebookpage_get_found_exist'] />

		        <cfelse>

			        <cfquery name="local.query" datasource="#variables.datasource#" result="qry">
			            INSERT INTO social_login_facebook_pages (

		                                                		pageID,
																facebookUserID,
																pageName,
																pageURL,
																pageCategory,
																pageAccessToken
			                                                )
			            VALUES (
			                        <cfqueryparam value="#arguments.pageID#" 			cfsqltype="cf_sql_varchar">,
			                        <cfqueryparam value="#arguments.facebookUserID#" 	cfsqltype="cf_sql_varchar">,
			                        <cfqueryparam value="#arguments.pageName#" 			cfsqltype="cf_sql_varchar">,
			                        <cfqueryparam value="#arguments.pageURL#" 			cfsqltype="cf_sql_varchar">,
			                        <cfqueryparam value="#arguments.pageCategory#" 		cfsqltype="cf_sql_varchar">,
			                        <cfqueryparam value="#arguments.pageAccessToken#" 	cfsqltype="cf_sql_varchar">	                                           
			                    )
			        </cfquery>

			        <cfset result['id'] = qry.GENERATED_KEY >
			        <cfset result['message'] = application.messages['socialfacebookpage_post_add_success'] />			     

			     </cfif>		        
		        
				<cfcatch>

			        <cfset result['message'] = errorMessage(message = 'socialfacebookpage_post_add_error', error = variables.cfcatch) />			     

					<cfset logAction( actionID = 1006, extra = "method: /facebookPage/POST", errorCatch = variables.cfcatch )>
					
					<cfreturn representationOf(result.message).withStatus(500) />

				</cfcatch>
			
			</cftry>
				 
			<cfset result['status'] = true />			

		  	<cfset logAction( actionID = 1005, extra = "method: /facebookPage/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

	<cffunction name="DELETE" access="public" output="true" returntype="Struct" hint="used to delete the facebook page details <code>DELETE</code>.">
		<cfargument name="pageID" type="numeric" required="true" hint="pageID">

		<cfset result = structNew() />
		<cfset result['message'] = ''>
	    <cfset result['status'] = false />

	    <cftry>

	        <cfquery name="local.query" datasource="#variables.datasource#" result="qry">
	        	DELETE FROM social_login_facebook_pages 
							WHERE 
								pageID = <cfqueryparam cfsqltype="cf_sql_numeric" 	value="#arguments.pageID#">
	        </cfquery>

	        <cfquery name="local.update" datasource="#variables.datasource#" result="isUpdate">

	        	UPDATE blogs SET 
	        		facebookPageURL =<cfqueryparam value="" cfsqltype="cf_sql_varchar"> ,
	        		facebookPageID  =<cfqueryparam value="" cfsqltype="cf_sql_varchar">
	        		WHERE facebookPageID = <cfqueryparam value="#arguments.pageID#" cfsqltype="cf_sql_varchar">

	        </cfquery>
	
	        <cfif NOT isUpdate.recordCount>

	        	<cfset result['status'] = false />
	        	<cfset result['message'] = application.messages['socialfacebookpage_delete_remove_error']>
	        	<cfreturn representationOf(result).withStatus(404) />

	        </cfif>

	    	<cfcatch>
				
				<cfset result.message = errorMessage( message = 'socialfacebookpage_delete_remove_error', error = variables.cfcatch)/>
				<cfset logAction( actionID = 1006, extra = "method: /facebookPage/DELETE", errorCatch = variables.cfcatch )>			
				<cfreturn representationOf( result.message ).withStatus(500) />

			</cfcatch>
			
		</cftry>

	        <cfset result['status'] = true />
			<cfset result.message = application.messages['socialfacebookpage_delete_remove_success']/>

		  	<cfset logAction( actionID = 1005, extra = "method: /facebookPage/DELETE" )>
		
			<cfreturn representationOf(result).withStatus(200) />


	</cffunction>
	
</cfcomponent>