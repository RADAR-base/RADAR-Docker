   -- Load all of the fields from the file
   DATA = LOAD '$inputFile' USING PigStorage(',') AS (path:chararray,
                                                    replication:int,
                                                    modTime:chararray,
                                                    accessTime:chararray,
                                                    blockSize:long,
                                                    numBlocks:int,
                                                    fileSize:long,
                                                    NamespaceQuota:int,
                                                    DiskspaceQuota:int,
                                                    perms:chararray,
                                                    username:chararray,
                                                    groupname:chararray);


   -- Grab just the path, size and modDate(in milliseconds)
   RELEVANT_FIELDS = FOREACH DATA GENERATE path, fileSize, ToMilliSeconds(ToDate(modTime, 'yyyy-MM-dd HH:mm', '+00:00')) as modTime:long;
   RELEVANT_FILES = FILTER RELEVANT_FIELDS BY ((modTime < ToMilliSeconds(ToDate('$time', 'yyyy-MM-dd HH:mm', '+00:00'))) AND (path matches '^((?!tmp).)*.avro'));
   -- DUMP RELEVANT_FILES;
   -- Load topics from the provided file
   TOPICS = LOAD '$topics' USING PigStorage() AS (topic:chararray);

   PATH_SIZE = FOREACH RELEVANT_FILES GENERATE path, fileSize;
   PATH_SIZE_TOPIC = CROSS PATH_SIZE, TOPICS;
   -- DUMP PATH_SIZE_TOPIC;
   PATH_MATCHES_TOPIC = FILTER PATH_SIZE_TOPIC BY (path matches SPRINTF('.*%s.*', topic));

   -- Calculate total file size
   SUM_FILE_SIZES = FOREACH (GROUP PATH_MATCHES_TOPIC ALL) GENERATE CONCAT('SUM OF FILES SIZES TO BE DELETED IN MB = ', (chararray)(SUM(PATH_MATCHES_TOPIC.fileSize) / 1024 / 1024));
   DUMP SUM_FILE_SIZES;
   FINAL_PATHS = FOREACH PATH_MATCHES_TOPIC GENERATE path;
   -- Save results
   -- DUMP FINAL_PATH;
   STORE FINAL_PATHS INTO '$outputFile';
