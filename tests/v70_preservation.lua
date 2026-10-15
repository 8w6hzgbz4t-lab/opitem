-- Compare actual catalog values and execute Version 69's existing regression suite.
return function(package, moduleRequire, baseline)
 local current=moduleRequire(package.Catalog)
 local original=moduleRequire(baseline.Catalog)
 local function same(a,b,path)
  assert(type(a)==type(b),'Changed type: '..path)
  if type(a)~='table' then assert(a==b,'Changed value: '..path);return end
  for key,value in pairs(a) do same(value,b[key],path..'.'..tostring(key)) end
  for key in pairs(b) do assert(a[key]~=nil,'Added value: '..path..'.'..tostring(key)) end
 end
 same(original.Items,current.Items,'Catalog.Items')
 same(original.SpawnSettings,current.SpawnSettings,'Catalog.SpawnSettings')
 same(original.Weights,current.Weights,'Catalog.Weights')
 local regression=moduleRequire(package.RegressionTests)(package)
 assert(regression.passed==13 and #regression.names==13,'Existing regression groups did not all execute')
 return string.format('%d catalog entries and all field values preserved; %d existing gameplay regression groups passed',#current.Items,regression.passed)
end
