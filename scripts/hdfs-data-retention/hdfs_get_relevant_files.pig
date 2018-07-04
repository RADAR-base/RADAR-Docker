   -- Load all of the fields from the file
   A = LOAD '$inputFile' USING PigStorage(',') AS (path:chararray,
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
   B = FOREACH A GENERATE path, fileSize, org.apache.pig.builtin.ToMilliSeconds(org.apache.pig.builtin.ToDate(modTime, 'yyyy-MM-dd HH:mm', '+00:00')) as modTime:long;
   C = FILTER B BY ((modTime < org.apache.pig.builtin.ToMilliSeconds(org.apache.pig.builtin.ToDate('$time', 'yyyy-MM-dd HH:mm', '+00:00'))) AND (path matches '^((?!tmp).)*.avro'));
   -- DUMP C;
   -- Load topics from the provided file
   D = LOAD '$topics' USING PigStorage() AS (topic:chararray);

   C_0 = FOREACH C GENERATE path, fileSize;
   C_1 = CROSS C_0, D;
   -- DUMP C_1;
   E = FILTER C_1 BY (path matches SPRINTF('.*%s.*', topic));

   -- Calculate total file size
   S = FOREACH (GROUP E ALL) GENERATE CONCAT('SUM OF FILES SIZES TO BE DELETED IN MB = ', (chararray)(org.apache.pig.builtin.SUM(E.fileSize) / 1024 / 1024));
   DUMP S;
   F = FOREACH E GENERATE path;
   -- Save results
   -- DUMP F;
   STORE F INTO '$outputFile';
