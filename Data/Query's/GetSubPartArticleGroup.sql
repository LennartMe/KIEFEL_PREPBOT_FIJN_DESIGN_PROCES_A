DECLARE @SubPartCode varchar(255)
SET @SubPartCode = '{SubPartCode}';


 SELECT p.PartCode,  
        p.PartGrpCode,
        PGM.[Description]            AS [Artikelhoofdgroep omschr.],  
        PGM.PartGrpMainCode,  
        PG.[Description]             AS [Artikelgroep omschr.]  
 FROM   dbo.T_Part                   AS p  
        LEFT JOIN dbo.T_PartGrp      AS PG  
             ON  PG.PartGrpCode = p.PartGrpCode  
        LEFT JOIN dbo.T_PartGrpMain  AS PGM  
             ON  PGM.PartGrpMainCode = PG.PartGrpMainCode  
        LEFT OUTER JOIN dbo.T_CustomFieldValue CFV  
             ON  CFV.IsahTableId = 12  
             AND CFV.IsahPrimKey = P.PartCode  
             AND CFV.FieldDefCode = N'500001'  
        LEFT OUTER JOIN dbo.T_CustomFieldPossibilityDesc CFPD  
             ON  CFPD.PossibilityID = CFV.PossibilityValue  
             AND CFPD.LangCode = N'NL'  
 WHERE  p.PartCode > N''  
        AND p.PartOBsInd = 0  
        AND PG.PartGrpCode NOT IN (N'SZ', N'PRV')  
        AND PGM.PartGrpMainCode NOT IN (N'PRV', N'PRO', N'FOLI', N'SPA', N'SA')  
		AND PartCode = @SubPartCode
 ORDER BY  
        p.PartCode;  
