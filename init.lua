
require 'torch'
require 'sys'
require 'paths'
require 'dok'


-- load C lib
require 'libknn'


local knn = {}

function knn.knn(...)

   local _, ref, query, k = dok.unpack(
      {...},
      'knn.knn',
      [[K-Nearest Neighbours]],
           
      {arg='ref', type='torch.FloatTensor',
       help='reference points (m x h) 2d tensor', req=true},
       
      {arg='query', type='torch.FloatTensor',
       help='query point(s) (n x h) 2d tensor or (h) 1d tensor', req=true},
             
      {arg='k', type='number',
       help='number of results returned per query point', default=1}
   )
   
   
   if(query:dim() == 1) then
     query = query:resize(1, query:size(1))
   end
   
   assert(query:dim() == 2 and ref:dim() == 2, "query must be 1d or 2d tensor (h or n x h), ref must be a 2d (h x m) tensor")
   assert(query:size(2) == ref:size(2), "query and ref must have equal size features")
--    assert(query:size(1) <= 65535 and ref:size(1) <= 65535, "maximum size permitted is 65535")
   
   k = math.min(k, ref:size(1))
   
   local distances, indices = libknn.knn(k, ref:t():contiguous(), query:t():contiguous())
   return distances:t(), indices:t()
end


function knn.lookup(...)

   local _, table, indexes = dok.unpack(
      {...},
      'knn.knn',
      [[K-Nearest Neighbours]],
           
      {arg='table', type='torch.*Tensor',
       help='table to index, 1d tensor', req=true},

      {arg='indexes', type='torch.IntTensor | torch.LongTensor | torch.ShortTensor | torch.ByteTensor',
       help='tensor of indexes into the table', req=true}
   )
   
     
   assert(table:dim() == 1)
   
   if(torch.typename(indexes) == "torch.ByteTensor") then
    return table.libknn.lookup_byte(table, indexes)
   elseif (torch.typename(indexes) == "torch.ShortTensor") then
     return table.libknn.lookup_short(table, indexes)
   elseif (torch.typename(indexes) == "torch.IntTensor") then
     return table.libknn.lookup_int(table, indexes)
   elseif (torch.typename(indexes) == "torch.LongTensor") then     
      return table.libknn.lookup_long(table, indexes)
   else
      assert(false, "indexes must have integer type") 
   end
     
end


return knn