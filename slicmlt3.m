function y=slicmlt3(x);
    y=ones(1,length(x));
    if x>=0.5
        y=1*y;
    elseif x<-0.5
    	y=-1*y;
    else
        y=0*y;
    end
    
    
