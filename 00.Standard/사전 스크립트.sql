if not exists(select top 1 1 from _TCADictionaryCommon where WordSeq = 51755) 
begin 
    insert into _TCADictionaryCommon(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51755, N'대여금등록', null, N'대여금등록', 0, getdate(), 0 
    insert into _TCADictionaryCommon(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51755, N'대여금등록', null, N'대여금등록', 0, getdate(), 0 
    insert into _TCADictionaryCommon(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51755, N'대여금등록', null, N'대여금등록', 0, getdate(), 0 
    insert into _TCADictionaryCommon(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51755, N'대여금등록', null, N'대여금등록', 0, getdate(), 0 
    insert into _TCADictionaryCommon(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51755, N'대여금등록', null, N'대여금등록', 0, getdate(), 0 

end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51821) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51822) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51822, N'납입회차', null, N'납입회차', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51822, N'납입회차', null, N'납입회차', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51822, N'납입회차', null, N'납입회차', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51822, N'납입회차', null, N'납입회차', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51822, N'납입회차', null, N'납입회차', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51823) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51823, N'원금납입액', null, N'원금납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51823, N'원금납입액', null, N'원금납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51823, N'원금납입액', null, N'원금납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51823, N'원금납입액', null, N'원금납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51823, N'원금납입액', null, N'원금납입액', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51824) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51824, N'이자납입액', null, N'이자납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51824, N'이자납입액', null, N'이자납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51824, N'이자납입액', null, N'이자납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51824, N'이자납입액', null, N'이자납입액', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51824, N'이자납입액', null, N'이자납입액', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51821) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51821, N'대여금내부코드', null, N'대여금내부코드', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51820) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51820, N'대여구분', null, N'대여구분', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51820, N'대여구분', null, N'대여구분', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51820, N'대여구분', null, N'대여구분', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51820, N'대여구분', null, N'대여구분', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51820, N'대여구분', null, N'대여구분', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51825) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51825, N'대여내역', null, N'대여내역', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51825, N'대여내역', null, N'대여내역', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51825, N'대여내역', null, N'대여내역', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51825, N'대여내역', null, N'대여내역', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51825, N'대여내역', null, N'대여내역', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51826) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51826, N'원금상환조건', null, N'원금상환조건', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51826, N'원금상환조건', null, N'원금상환조건', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51826, N'원금상환조건', null, N'원금상환조건', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51826, N'원금상환조건', null, N'원금상환조건', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51826, N'원금상환조건', null, N'원금상환조건', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51827) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51827, N'납입계획생성', null, N'납입계획생성', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51827, N'납입계획생성', null, N'납입계획생성', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51827, N'납입계획생성', null, N'납입계획생성', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51827, N'납입계획생성', null, N'납입계획생성', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51827, N'납입계획생성', null, N'납입계획생성', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51828) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51828, N'대여금종류', null, N'대여금종류', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51828, N'대여금종류', null, N'대여금종류', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51828, N'대여금종류', null, N'대여금종류', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51828, N'대여금종류', null, N'대여금종류', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51828, N'대여금종류', null, N'대여금종류', 0, getdate(), 0 
end 

if not exists(select top 1 1 from _TCADictionary where WordSeq = 51829) 
begin 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 1, 51829, N'대여내부코드', null, N'대여내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 2, 51829, N'대여내부코드', null, N'대여내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 3, 51829, N'대여내부코드', null, N'대여내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 4, 51829, N'대여내부코드', null, N'대여내부코드', 0, getdate(), 0 
    insert into _TCADictionary(LanguageSeq,WordSeq,Word,WordSite,Description,LastUserSeq,LastDateTime,CompanySeq) select 5, 51829, N'대여내부코드', null, N'대여내부코드', 0, getdate(), 0 
end 



