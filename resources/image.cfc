<cfcomponent extends="taffyAPI.base" taffy:uri="/image/{id}" hint="Using this user can update and delete the images record from images table">
	<cffunction name="PUT" access="public" output="false" hint="used to update the image record in images table and also uploading the image file into amazon S3">		
		<cfargument name="id"			    type="numeric"	required="true" hint="id refers to imageID which needs to be updated">
		<cfargument name="entityID"			type="numeric"	required="true" hint="entityID refers to id from which the image is uploaded. For example (recipeID, userID & etc..,)" >
		<cfargument name="entityTypeName"	type="string"	required="true" hint="entityName refers to name from which the image is uploaded. For example (recipe, user & etc..,)" >
		<cfargument name="cgi" 				type="struct" 	required="false" default="#structNew()#">

		<cftry>
			<!--- // START: form validation --->
			<cfscript>
			
				local.error  	   = false;
				local.errors 	   = "";
				local.errorsForLog = "";
				result['status'] 	   = false;
				result['message'] 	   = "";
		  
		 			
				// verify imageID
				if ( len(TRIM(arguments.id)) EQ 0 OR arguments.id EQ 0 ) {
					local.errors = listAppend(local.errors, "imageID");
					local.errorsForLog = listAppend(local.errorsForLog, "imageID missing");
				}

				// verify entityID
				if ( len(TRIM(arguments.entityID)) EQ 0 OR arguments.entityID EQ 0 ) {
					local.errors = listAppend(local.errors, "entityID");
					local.errorsForLog = listAppend(local.errorsForLog, "entityID missing");
				}

				// verify entityTypeName
				if ( len(TRIM(arguments.entityTypeName)) EQ 0 ) {
					local.errors = listAppend(local.errors, "entityTypeName");
					local.errorsForLog = listAppend(local.errorsForLog, "entityTypeName missing");
				}								

		 		// START: any errors?
				if ( ListLen(local.errors) GT 0 ) { 
					local.error = true; 
						
					// Log Invalid Input  

					result.errors 		= local.errors;
					logAction( actionID = 64, extra = local.errorsForLog, cgi = arguments.cgi );
					result.errorsForLog = local.errorsForLog;
					
					// message: 431 - 'Profile Picture: Invalid Input' - 'You have not provided an image file. Please try again'
					result.message = application.messages['image_put_input_invalid'];

					return representationOf(result).withStatus(406);
					
				} // END: any errors?

				arguments.error  = local.error;
				arguments.errors = local.errors;

			</cfscript>
	 		<!--- // END: form validation --->

			<!--- // START: NO ERRORS? THEN upload --->
			<cfif ListLen(local.errors) EQ 0>
				
				<cfset local.GUID = CreateUUID()>

				<cfquery name="local.query" datasource="#variables.datasource#" result="local.qry">
					SELECT imagePath
					 FROM images WHERE imageID = <cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.id#">
					 				AND active = <cfqueryparam cfsqltype="cf_sql_integer" 	value="0">
				</cfquery>

				<!--- // START: Image file? --->	
				<cfif local.qry.recordCount NEQ 1 >
		        
					<cfscript>	
						// Log Invalid Input  
						logAction( actionID = 64, extra = local.errorsForLog, cgi = arguments.cgi );
						
						// message: 431 - 'Uploaded Picture: Invalid Input' - 'You have not provided an image file. Please try again.'
						result.message =  application.messages['image_get_found_error'];

						return representationOf(result).withStatus(404);

					</cfscript>	        
		        
		        <cfelse>

		        	<cfset local.uploadedImagePath  = expandPath(application.uploadedImagePath) >
		        	<cfset local.convertedImgePath  = expandPath(application.uploadedS3ImagePath) >
		        	<cfset local.imageName = listLast(local.query.imagePath, '/') >

		        	 <!--- Checking whether directory exist or not--->
				    <cfif NOT directoryExists(local.convertedImgePath)>

				    	<cfset directorycreate(local.convertedImgePath)>

				    </cfif>

		        	<cfif arguments.entityTypeName EQ 'recipe' >
						
						<cfset local.entityName 	 = 'recipes' >
						<cfset local.fullWidthRatio  = 1200>
						<cfset local.thumbWidthRatio = 312>
						<cfset local.miniWidthRatio  = 35>
						<cfset local.entityTypeID 	 = 10>

					<cfelseif arguments.entityTypeName EQ 'influencer' >
						
						<cfset local.entityName 	 = 'influencers' >
						<cfset local.fullWidthRatio  = 1200>
						<cfset local.thumbWidthRatio = 220>
						<cfset local.miniWidthRatio  = 35>
						<cfset local.entityTypeID 	 = 4>

					<cfelseif arguments.entityTypeName EQ 'direction' >
						
						<cfset local.entityName 	 = 'directions' >
						<cfset local.fullWidthRatio  = 1200>
						<cfset local.thumbWidthRatio = 220>
						<cfset local.miniWidthRatio  = 35>
						<cfset local.entityTypeID 	 = 11>

					<cfelseif arguments.entityTypeName EQ 'blog' >
						
						<cfset local.entityName 	 = 'blogs' >
						<cfset local.fullWidthRatio  = 1200>
						<cfset local.thumbWidthRatio = 220>
						<cfset local.miniWidthRatio  = 35>
						<cfset local.entityTypeID 	 = 3>

					<cfelseif arguments.entityTypeName EQ 'comment' >
						
						<cfset local.entityName 	 = 'comments' >
						<cfset local.fullWidthRatio  = 1200>
						<cfset local.thumbWidthRatio = 220>
						<cfset local.miniWidthRatio  = 35>
						<cfset local.entityTypeID 	 = 6>

					</cfif>			     	

					<cfimage 							
						action = "info"
						source = "#local.uploadedImagePath##local.imageName#"
						structname = "pictureDetails"
						>

					<cfset local.myImage = ImageRead("#local.uploadedImagePath##local.imageName#") >
					<cfset local.imageEXT = listlast(local.imageName,'.') >

					<!--- START: Images resize process --->

					<!--- START: convertion for image full version --->

					<cfset local.fullVersionName  = "#arguments.entityTypeName#_#arguments.entityID#_#arguments.id#_#local.GUID#.#local.imageEXT#" >
					<cfset local.fullVersionPath  = "#local.convertedImgePath##local.fullVersionName#" >

					<cfset local.fullHeightRatio  = int((pictureDetails.height / pictureDetails.width) * local.fullWidthRatio) />

					<cfset ImageResize(local.myImage, 1200, local.fullHeightRatio) >								
					<cfset ImageWrite(local.myImage, local.fullVersionPath, 1) >
					
					<!--- END: convertion for image full version --->

					<!--- START: convertion for image thumb version --->

					<cfset local.thumbVersionName  = "#arguments.entityTypeName#_#arguments.entityID#_#arguments.id#_#local.GUID#_thumb.#local.imageEXT#" >
					<cfset local.thumbVersionPath  = "#local.convertedImgePath##local.thumbVersionName#" >					
					
					<cfset local.thumbHeightRatio = (pictureDetails.height / pictureDetails.width) * local.thumbWidthRatio >

					<cfset ImageResize(local.myImage, local.thumbWidthRatio, local.thumbHeightRatio) >								
					<cfset ImageWrite(local.myImage, local.thumbVersionPath, 1) >
					
					<!--- END: convertion for image thumb version --->

					<!--- START: convertion for image mini version --->

					<cfset local.miniVersionName  = "#arguments.entityTypeName#_#arguments.entityID#_#arguments.id#_#local.GUID#_mini.#local.imageEXT#" >
					<cfset local.miniVersionPath  = "#local.convertedImgePath##local.miniVersionName#" >

					<cfset local.miniHeightRatio  = int((pictureDetails.height / pictureDetails.width) * local.miniWidthRatio) />

					<cfset ImageResize(local.myImage, 35, local.miniHeightRatio) >								
					<cfset ImageWrite(local.myImage, local.miniVersionPath, 1) >

					<!--- END: convertion for image mini version --->
					
					<!--- END: Images resize process --->

					<!--- Deleting the original image file. --->
					<cfset FileDelete("#local.uploadedImagePath##local.imageName#") >

					<cfset local.bucketName = 'images.yummienation.com' />

					<!--- Uploading different version image files into amazon S3   --->

					<cfset local.S3FullVersionUpload  = application.dataObj.uploadToS3( fileName = local.fullVersionName,  subfolderName = local.entityName, localPath = local.convertedImgePath, bucketName = local.bucketName ) />
					<cfset local.S3ThumbVersionUpload = application.dataObj.uploadToS3( fileName = local.thumbVersionName, subfolderName = local.entityName, localPath = local.convertedImgePath, bucketName = local.bucketName ) />
					<cfset local.S3MiniVersionUpload  = application.dataObj.uploadToS3( fileName = local.miniVersionName,  subfolderName = local.entityName, localPath = local.convertedImgePath, bucketName = local.bucketName ) />
					
					
		 			<!--- START: inserting Image Details On amazonS3 success? --->
					<cfif ( NOT local.S3FullVersionUpload.status OR NOT local.S3ThumbVersionUpload.status OR NOT local.S3MiniVersionUpload.status ) >
						
						<cfthrow />

					<cfelse>							

						<cfquery datasource="#variables.datasource#" name="local.query" result="local.qry">
							UPDATE images SET 											
										imageName 			= <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#local.fullVersionName#">,
										imageAlt 			= <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#local.entityName# image">,
										imagePath 			= <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#application.assets_imagePath#/#local.entityName#">,
										imageFileName 		= <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#local.fullVersionName#">,
										imageFileNameHalf 	= <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#local.miniVersionName#">,
										imageThumbFileName 	= <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#local.thumbVersionName#">,
										imageUpdateDate 	= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
										active 				= <cfqueryparam cfsqltype="cf_sql_integer" 	value="1">,
										entityID			= <cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.entityID#">,
										entityTypeID		= <cfqueryparam cfsqltype="cf_sql_integer" 	value="#local.entityTypeID#">
									WHERE
										imageID = <cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.id#">
						</cfquery>								

						<!--- Deleting the local uploaded file. --->
						
						<cfset FileDelete(local.fullVersionPath) />
						<cfset FileDelete(local.thumbVersionPath) />
						<cfset FileDelete(local.miniVersionPath) />						
						
						<cfset result.status  = true >					

						<!--- Log Uploaded Uploaded image --->
						<cfset logAction( actionID = 66, extra = "method: /images/POST" ) />
						
						<!---  message: 430 - 'Uploaded image: Updated' - 'Your #arguments.entityTypeName# image was uploaded successfully.' --->
						<cfset result.message = "#arguments.entityTypeName#"& application.messages['image_put_update_success'] />

						<cfreturn representationOf(result).withStatus(200) />

					</cfif> 
					<!--- // END: insertImage TO amazonS3 success? --->					
				</cfif>
    			<!--- // END: Image file? ---> 	
			</cfif>
			<!--- // END: NO ERRORS? THEN upload --->

			<cfcatch>
		
				<cfscript>	
					// Log Upload Error
					logAction( actionID = 65, extra = local.errorsForLog, cgi = arguments.cgi );
					
					// message: 433 - 'Update Picture: Error' - 'There was a problem with updating the image details. Please try again.'
					result.message = errorMessage(message = 'image_put_update_error', error = variables.cfcatch);
					return representationOf(result.message).withStatus(500);

				</cfscript>	
			
			</cfcatch>

		</cftry>

	</cffunction>

	<cffunction name="DELETE" access="public" output="false" hint="used to delete image record from images table and amazon S3">		
		<cfargument name="id"	type="numeric"	required="true"  hint="id refers to imageID which needs to be deleted" >		
		<cfargument name="cgi" 	type="struct" 	required="false" default="#structNew()#" hint="" >

		<cftry>
			<!--- // START: form validation --->
			<cfscript>
			
				local.error  	   = false;
				local.errors 	   = "";
				local.errorsForLog = "";
				result['status'] 	   = false;
				result['message'] 	   = "";
		  
		 			
				// verify imageID
				if ( len(TRIM(arguments.id)) EQ 0 OR arguments.id EQ 0 ) {
					local.errors = listAppend(local.errors, "imageID");
					local.errorsForLog = listAppend(local.errorsForLog, "imageID missing");
				}												

		 		// START: any errors?
				if ( ListLen(local.errors) GT 0 ) { 
					local.error = true; 
						
					// Log Invalid Input  

					result.errors 		= local.errors;
					logAction( actionID = 64, extra = local.errorsForLog, cgi = arguments.cgi );
					result.errorsForLog = local.errorsForLog;
					
					// message: 431 - 'DELETING PICTURE: Invalid Input' - 'You have not provided a VALID imageID . Please try again'
					result.message = application.messages['image_delete_remove_error'];

					return representationOf(result).withStatus(406);
					
				} // END: any errors?

				arguments.error  = local.error;
				arguments.errors = local.errors;

			</cfscript>
	 		<!--- // END: form validation --->

			<!--- // START: NO ERRORS? THEN upload --->
			<cfif ListLen(local.errors) EQ 0>
				
				<cfset local.GUID = CreateUUID()>

				<cfquery name="local.query" datasource="#variables.datasource#" result="local.qry">
					SELECT  imageFileName,
							imageFileNameHalf,
							imageThumbFileName,
							imagePath
					 FROM images WHERE imageID = <cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.id#">
				</cfquery>

				<!--- // START: Image file? --->	
				<cfif NOT local.qry.recordCount >
		        
					<cfscript>	
						// Log Invalid Input  
						logAction( actionID = 64, extra = local.errorsForLog, cgi = arguments.cgi );
						
						// You have not provided an image file. Please try again.
						result.message =  application.messages['image_delete_invalid_error'];

						return representationOf(result).withStatus(404);

					</cfscript>	        
		        
		        <cfelse>		        	

					<!--- Deleting different version image files from amazon S3   --->

					<cfset local.bucketName = 'images.yummienation.com'&'/'&listLast(local.query.imagePath,'/') >

					<cfset local.S3FullVersionUpload  = application.s3Obj.deleteObject( bucketName = local.bucketName, fileKey = local.query.imageFileName ) />
					<cfset local.S3ThumbVersionUpload = application.s3Obj.deleteObject( bucketName = local.bucketName, fileKey = local.query.imageFileNameHalf ) />
					<cfset local.S3MiniVersionUpload  = application.s3Obj.deleteObject( bucketName = local.bucketName, fileKey = local.query.imageThumbFileName ) />
					
		 			<!--- START: Deleting Image Details On amazonS3 success? --->
					<cfif ( NOT local.S3FullVersionUpload OR NOT local.S3ThumbVersionUpload OR NOT local.S3MiniVersionUpload ) >
						
						<cfthrow />

					<cfelse>							

						<cfquery datasource="#variables.datasource#" name="local.query" result="local.qry">
							DELETE FROM images 
									WHERE
										imageID = <cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.id#">
						</cfquery>						
						
						<cfset result.status  = true >					

						<!--- Log deleting image --->
						<cfset logAction( actionID = 66, extra = "method: /images/DELETE" ) />
						
						
						<cfset result.message = application.messages['image_delete_remove_success'] />

						<cfreturn representationOf(result).withStatus(200) />

					</cfif> 
					<!--- // END: Deleting Image Details On amazonS3 success? --->					
				</cfif>
    			<!--- // END: Image file? ---> 	
			</cfif>
			<!--- // END: NO ERRORS? THEN delete --->

			<cfcatch>
		
				<cfscript>	
					// Log delete Error
					logAction( actionID = 65, extra = local.errorsForLog, cgi = arguments.cgi );
					
					result.message = errorMessage( message = 'image_delete_remove_error', error = variables.cfcatch );
					return representationOf(result).withStatus(500);

				</cfscript>	
			
			</cfcatch>

		</cftry>

	</cffunction>

</cfcomponent>