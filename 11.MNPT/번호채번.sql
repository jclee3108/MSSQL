INSERT INTO _TCOMCreateNoDefine(CompanySeq,TableName,DefineName,IsAutoCreate,Composition,SMYMD,SerialNoCnt,SMFirstInitialUnit,SMSecondInitialUnit,SMThirdInitialUnit,NoColumnName,BaseDateColumnName,FirstInitialColumnName,SecondInitialColumnName,ThirdInitialColumnName,LastUserSeq,LastDateTime,IsSite)SELECT A.CompanySeq,N'mnpt_TPJTEERentToolContract',N'외부장비임차계약번호_mnpt',N'1',N'(A)(B)',1048001,4,0,0,0,N'ContractNo',N'ContractDate',N'',N'',N'',167,'2017-11-16 13:43:36.187',NULL from _TCACompany AS A where not exists (Select 1 from _TCOMCreateNoDefine where companyseq = a.companyseq and tablename = 'mnpt_TPJTEERentToolContract') 