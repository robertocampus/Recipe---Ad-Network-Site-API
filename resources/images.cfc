<cfcomponent extends="taffyAPI.base" taffy:uri="/images/" hint="Using this user can get and add the images record in the images table">

	<cffunction name="POST" access="public" output="false" hint="used to add new image record in images table">		
		<cfargument name="uploadedFrom" 	type="string" 	required="true">
		<cfargument name="uploadedPicture" 	type="string" 	required="true">
		<cfargument name="cgi" 				type="struct" 	required="false" default="#structNew()#">	
		  	
		<cftry>
			<!--- // START: form validation --->
			<cfscript>
			
				local.error  	   = false;
				local.errors 	   = "";
				local.errorsForLog = "";
		  		result['message']  = "";
		  		result['status']   = "";
		 		result['error']	   = "";
				// verify uploadedPicture
				if ( len(TRIM(arguments.uploadedPicture)) EQ 0 ) {
					local.errors = listAppend(local.errors, "uploadedPicture");
					local.errorsForLog = listAppend(local.errorsForLog, "uploadedPicture missing");
				}			

		 		// START: any errors?
				if ( ListLen(local.errors) GT 0 ) { 
					local.error = true; 
						
					// Log Invalid Input  
					logAction( actionID = 64, extra = local.errorsForLog, cgi = arguments.cgi );

					result.errors 		= local.errors;
					result.errorsForLog = local.errorsForLog;
					
					// message: 431 - 'Profile Picture: Invalid Input' - 'You have not provided an image file. Please try again'
					result.message 	= application.messages['images_post_addimage_error'];

					return representationOf(result).withStatus(404);
					
				} // END: any errors?
			 					
				

				arguments.error  = local.error;
				arguments.errors = local.errors;

			</cfscript>
	 		
			<!--- // START: NO ERRORS? THEN upload --->
			<cfif ListLen(local.errors) EQ 0>

				<cfset local.imageFilePath = expandPath(application.uploadedImagePath) >

			    <!--- Checking whether directory exist or not--->
			    <cfif NOT directoryExists(local.imageFilePath)>

			    	<cfset directorycreate(local.imageFilePath)>

			    </cfif>
		    
				
				<cfset local.GUID = CreateUUID()>	
					
				<cffile action  = "upload" 
	        	  	  fileField = "uploadedPicture" 
	        		destination = "#local.imageFilePath#" 
	         	   nameConflict = "MakeUnique"
	         	   mode 		= "777"
	         	   result  		= "uploadedFileDetails" >
	         	
	         	<cfset local.fileName = "#arguments.uploadedFrom#_#local.GUID#.#uploadedFileDetails.serverFileExt#" />
				
				<cffile  
				    action = "rename"
				    destination = "#local.imageFilePath##local.fileName#" 
				    source = "#local.imageFilePath##uploadedFileDetails.serverFile#"				    
				    mode = "777">				
	         	   
				<!--- // START: Image file? --->	
				<cfif NOT ListFindNoCase("jpg,gif,png", uploadedFileDetails.serverFileExt)>  
		        
					<cfscript>	
						// Log Invalid Input  
						logAction( actionID = 64, extra = local.errorsForLog, cgi = arguments.cgi );
						
						result.message 	= application.messages['images_post_validimage_error'];

						return representationOf(result).withStatus(404);

					</cfscript>	        
		        
		        <cfelse>

			     	<!--- // START: File Saved? --->
				    <cfif NOT uploadedFileDetails.FILEWASSAVED>   
						<!--- throw error --->
						<cfthrow>   
					<cfelse>

						<!--- Insert image details without imageName --->
						<cfquery datasource="#variables.datasource#" name="local.query" result="qry">
							INSERT INTO images 
										( 
											imagePath,
											imageCreateDate,
											active
										)
							VALUES   (										
										<cfqueryparam cfsqltype="cf_sql_varchar" 	value="#application.urlSSL##application.uploadedImagePath##local.fileName#">,
										<cfqueryparam cfsqltype="cf_sql_timestamp"  value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
										<cfqueryparam cfsqltype="cf_sql_integer" 	value="0">
									)
						</cfquery>		

						<cfset local.imageID = '#qry.GENERATED_KEY#' >	

						<cfquery name="result.query" datasource="#variables.datasource#" result="local.resultQuery">
							SELECT 	imageID,									
									imagePath
							FROM images
							WHERE imageID = <cfqueryparam cfsqltype="cf_sql_integer" 	value="#local.imageID#">
						</cfquery>
											
						<!--- Log Uploaded Uploaded Picture --->
						<cfset logAction( actionID = 66, extra = "method: /images/POST" ) />
								
						<cfset result.message 	= application.messages['images_post_addimage_success'] />						

						<cfreturn representationOf(result).withStatus(200) />
					
					</cfif> 
					<!--- // END: File Saved? ERROR --->  
				</cfif>
    			<!--- // END: Image file? ---> 	
			</cfif>
			<!--- // END: NO ERRORS? THEN upload --->

			<cfcatch>
		
				<cfscript>	
					// Log Upload Error
					logAction( actionID = 65, extra = local.errorsForLog, cgi = arguments.cgi );
					
					result.message = errorMessage(message = 'images_post_addimage_error', error = variables.cfcatch);
					return representationOf(result.message).withStatus(500);

				</cfscript>	
			
			</cfcatch>

		</cftry>
		 

	</cffunction>

	<cffunction name="GET" access="public" output="true" >
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="false" hint="Recipe Listing Filters struct">
		<cfargument name="pagination"	type="struct" default="#StructNew()#" required="false" hint="Recipe Listing pagination struct">

		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
		<cfset result['rows'] = "">
		<cfparam name="arguments.pagination.orderCol" default="ImageID">

		<cfscript>

			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>
		<cftry>
			
			<cfquery name="result.query" datasource="#variables.datasource#">
				SELECT 
					ImageID,
					CONCAT( imagePath, '/', imageName ) AS 'FullSize_Image',
					CONCAT( imagePath, '/', imageThumbFileName ) AS 'Thumb_Image',
					CONCAT( imagePath, '/', imageFileNameHalf ) AS 'mini_Image',
					imageAlt,
					imageCreateDate,
					imageUpdateDate,
					active,
					userID,
					blogID
				FROM images
				WHERE 1=1

				<cfif StructCount(arguments.filters) GT 0>
								
					<cfloop collection="#arguments.filters#" item="thisFilter">

						<cfif thisFilter EQ "ImageID" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND ImageID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "imageName" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND imageName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "imageAlt" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND imageAlt = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "imageFileName" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND imageFileName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "imageFileNameHalf" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND imageFileNameHalf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "imageThumbFileName" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND imageThumbFileName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "imagePath" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND imagePath = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "userID" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "blogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						</cfif>

					</cfloop>

				</cfif>

				AND active = 1

				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# limit #arguments.pagination.offset#, #arguments.pagination.limit# 

			</cfquery>

			<cfcatch>

				<cfscript>	
					
					logAction( actionID = 666, extra = local.errorsForLog, cgi = arguments.cgi );
					
					result.message =errorMessage( message = 'database_query_error', error = variables.cfcatch);
					return representationOf(result.message).withStatus(500);

				</cfscript>	

			</cfcatch>

		</cftry>

		<cfquery datasource="#variables.datasource#" name="result.rows">

			SELECT FOUND_ROWS() AS total_count;

		</cfquery>	
		
		<cfif result.rows.total_count EQ 0 >
			<cfset result.message = application.messages['images_get_found_error']>
			<cfreturn noData().withStatus(404) />
		</cfif>


		<!--- <cfset result.total_rows = result.rows.total_count> --->

		<cfset result.status  = true />
		<cfset result.message = application.messages['images_get_found_success'] />

		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>

</cfcomponent>
